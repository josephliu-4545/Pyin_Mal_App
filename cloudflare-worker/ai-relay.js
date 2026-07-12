/**
 * ai-relay.js — Pyin Mal AI relay (Cloudflare Worker)
 *
 * Gemini's API is geoblocked in Myanmar (it returns HTTP 400 "user location is
 * not supported"). This Worker runs on Cloudflare's edge — reachable from
 * Myanmar AND able to reach Gemini — so it relays the call:
 *
 *     App  →  this Worker  →  Gemini  →  this Worker  →  App
 *
 * The Gemini API key lives here as a secret (env.GEMINI_API_KEY), never in the
 * shipped app.
 *
 * ── Deploy (free, no credit card) ─────────────────────────────────────────────
 * Option A — Dashboard:
 *   1. Sign up at https://dash.cloudflare.com (email only, no card).
 *   2. Workers & Pages → Create → Create Worker → name it e.g. "pyin-mal-ai".
 *   3. Edit code → paste this whole file → Deploy.
 *   4. Settings → Variables and Secrets → add a Secret:
 *        Name: GEMINI_API_KEY   Value: <your Gemini key>
 *   5. Copy the URL (https://pyin-mal-ai.<your-subdomain>.workers.dev) and put it
 *      in the app's .env as AI_RELAY_URL.
 *
 * Option B — CLI:
 *   npm i -g wrangler
 *   wrangler login
 *   wrangler deploy ai-relay.js --name pyin-mal-ai
 *   wrangler secret put GEMINI_API_KEY        # paste the key when prompted
 *
 * ── Request contract ──────────────────────────────────────────────────────────
 *   POST <worker-url>
 *   { "model": "gemini-2.5-flash", "body": { ...Gemini generateContent body... } }
 *
 * Returns Gemini's response JSON verbatim (same status code), so the app parses
 * candidates[0].content.parts[0].text exactly as it would calling Gemini direct.
 */

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS });
    }
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return json({ error: "Invalid JSON body" }, 400);
    }

    // ── Image upload relay ────────────────────────────────────────────────
    // The browser can't reach the free image hosts directly (no CORS / IP
    // bans), so the app POSTs { upload: true, name, image: <base64> } here
    // and the Worker forwards it to freeimage.host from Cloudflare's edge.
    // Responds { url: "https://iili.io/...." }.
    if (payload.upload === true) {
      if (!payload.image) return json({ error: "image (base64) is required" }, 400);
      try {
        const form = new URLSearchParams();
        form.set("key", env.FREEIMAGE_KEY || "6d207e02198a847aa98d0a2a901485a5");
        form.set("format", "json");
        form.set("source", payload.image);
        const up = await fetch("https://freeimage.host/api/1/upload", {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: form.toString(),
        });
        const data = await up.json();
        const url = data && data.image && data.image.url;
        if (!url) return json({ error: "host declined", detail: data }, 502);
        return json({ url }, 200);
      } catch (e) {
        return json({ error: "Upload relay failed: " + e.message }, 502);
      }
    }

    const model = payload.model || "gemini-2.5-flash";
    const body = payload.body;
    if (!body) return json({ error: "body is required" }, 400);

    const key = env.GEMINI_API_KEY;
    if (!key) return json({ error: "GEMINI_API_KEY not configured on the Worker" }, 500);

    const url =
      "https://generativelanguage.googleapis.com/v1beta/models/" +
      encodeURIComponent(model) +
      ":generateContent?key=" +
      encodeURIComponent(key);

    let upstream;
    try {
      upstream = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
    } catch (e) {
      return json({ error: "Upstream fetch failed: " + e.message }, 502);
    }

    // Pass Gemini's JSON straight through so the app parses it identically.
    const text = await upstream.text();
    return new Response(text, {
      status: upstream.status,
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  },
};
