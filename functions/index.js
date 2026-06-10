const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");

/**
 * scanClothing — Firebase Cloud Function (us-central1)
 *
 * Proxies Gemini vision calls from the Flutter app.
 * Required because Google AI Studio is geoblocked in Myanmar.
 *
 * Request data:
 *   imageBase64    — JPEG image as base64 string
 *   productsContext — newline-separated product catalog string
 *
 * Response data:
 *   text — raw JSON string from Gemini
 */
exports.scanClothing = onCall({ region: "us-central1" }, async (request) => {
  const { imageBase64, productsContext } = request.data;

  if (!imageBase64 || typeof imageBase64 !== "string") {
    throw new HttpsError("invalid-argument", "imageBase64 is required");
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new HttpsError("internal", "GEMINI_API_KEY not configured");
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-flash",
    generationConfig: { responseMimeType: "application/json" },
  });

  const prompt = `You are a fashion AI for the Pyin Mal app. Analyze the clothing item in this image.

Available products:
${productsContext}

Instructions:
1. Identify the clothing type, color, style, and graphic details in the image.
2. Return the top 1-4 most visually similar products from the list, ranked best match first.
3. Return ONLY valid JSON, no markdown:
{"matched_product_ids": ["id1", "id2", "id3"], "item_type": "<what you see, e.g. black graphic hoodie>"}

Only include IDs that are genuinely similar. Return an empty array if nothing matches.`;

  const result = await model.generateContent([
    { text: prompt },
    { inlineData: { mimeType: "image/jpeg", data: imageBase64 } },
  ]);

  const text = result.response.text();
  return { text };
});
