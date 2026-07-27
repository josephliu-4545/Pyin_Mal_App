// scripts/find_catbox.js
//
// One-off utility: finds every Firestore field (any collection, any depth)
// whose value contains a catbox.moe URL, so old try-on / wardrobe / OOTD photo
// links uploaded back when catbox.moe was the image host can be recovered.
//
// Auth: reuses the Firebase CLI login (refresh token in the CLI's configstore).
// No service-account key needed. Read-only — it never writes to Firestore.
//
//   node scripts/find_catbox.js
//
// Output: prints matches to the console and writes catbox_urls.csv next to it.

const fs = require('fs');
const os = require('os');
const path = require('path');

const PROJECT_ID = 'ta-chat-nhate';
const NEEDLE = 'catbox.moe'; // matches files.catbox.moe and any catbox link

// Public OAuth client the Firebase CLI itself uses (from firebase-tools/lib/api.js).
const CLIENT_ID =
  process.env.FIREBASE_CLIENT_ID ||
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET =
  process.env.FIREBASE_CLIENT_SECRET || 'j9iVZfS8kkCEFUPaAeJV0sAi';

// Collection IDs used by the app. `allDescendants` collection-group queries
// scan each id wherever it lives (top-level or nested under a document), so
// subcollections like wardrobe/likes/views are covered no matter how nested.
const COLLECTIONS = [
  'users',
  'outfitPosts',
  'resellPosts',
  'tryOnGallery',
  'wardrobe',
  'sizeCharts',
  'aiConversations',
  'searches',
  'purchases',
  'likes',
  'views',
];

function readRefreshToken() {
  const p = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const j = JSON.parse(fs.readFileSync(p, 'utf8'));
  const rt = j.tokens && j.tokens.refresh_token;
  if (!rt) throw new Error('No refresh_token in ' + p + ' — run `firebase login` first.');
  return rt;
}

async function getAccessToken() {
  const body = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: readRefreshToken(),
    grant_type: 'refresh_token',
  });
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!res.ok) throw new Error('Token refresh failed: ' + res.status + ' ' + (await res.text()));
  return (await res.json()).access_token;
}

// Walk a Firestore REST document's fields, yielding [fieldPath, stringValue]
// for every string anywhere in the tree (nested maps/arrays included).
function* strings(fields, prefix = '') {
  for (const [key, val] of Object.entries(fields || {})) {
    yield* stringsOfValue(val, prefix ? prefix + '.' + key : key);
  }
}
function* stringsOfValue(val, fieldPath) {
  if (val == null) return;
  if (typeof val.stringValue === 'string') {
    yield [fieldPath, val.stringValue];
  } else if (val.mapValue) {
    yield* strings(val.mapValue.fields, fieldPath);
  } else if (val.arrayValue) {
    const items = (val.arrayValue.values) || [];
    for (let i = 0; i < items.length; i++) {
      yield* stringsOfValue(items[i], fieldPath + '[' + i + ']');
    }
  }
}

async function runQueryPage(token, collectionId, startAfterName) {
  const structuredQuery = {
    from: [{ collectionId, allDescendants: true }],
    orderBy: [{ field: { fieldPath: '__name__' }, direction: 'ASCENDING' }],
    limit: 300,
  };
  if (startAfterName) {
    structuredQuery.startAt = {
      before: false,
      values: [{ referenceValue: startAfterName }],
    };
  }
  const url =
    'https://firestore.googleapis.com/v1/projects/' +
    PROJECT_ID +
    '/databases/(default)/documents:runQuery';
  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery }),
  });
  if (!res.ok) throw new Error('runQuery ' + collectionId + ' failed: ' + res.status + ' ' + (await res.text()));
  return res.json(); // array of { document?, readTime }
}

async function scanCollection(token, collectionId, matches) {
  let startAfter = null;
  let scanned = 0;
  for (;;) {
    const rows = await runQueryPage(token, collectionId, startAfter);
    const docs = rows.filter((r) => r.document).map((r) => r.document);
    if (docs.length === 0) break;
    for (const doc of docs) {
      scanned++;
      for (const [field, str] of strings(doc.fields)) {
        if (str.includes(NEEDLE)) {
          matches.push({ collection: collectionId, docPath: doc.name.split('/documents/')[1], field, url: str });
        }
      }
    }
    startAfter = docs[docs.length - 1].name;
    if (docs.length < 300) break; // last page
  }
  return scanned;
}

(async () => {
  console.log('Refreshing access token from Firebase CLI login...');
  const token = await getAccessToken();
  console.log('Scanning project "' + PROJECT_ID + '" for "' + NEEDLE + '" links...\n');

  const matches = [];
  for (const c of COLLECTIONS) {
    try {
      const n = await scanCollection(token, c, matches);
      console.log('  ' + c.padEnd(16) + ' scanned ' + n + ' docs');
    } catch (e) {
      console.log('  ' + c.padEnd(16) + ' ERROR: ' + e.message);
    }
  }

  console.log('\n=== ' + matches.length + ' catbox link(s) found ===');
  for (const m of matches) {
    console.log('  [' + m.collection + '] ' + m.docPath + ' . ' + m.field + '\n    ' + m.url);
  }

  const csv =
    'collection,docPath,field,url\n' +
    matches
      .map((m) => [m.collection, m.docPath, m.field, m.url].map((v) => '"' + String(v).replace(/"/g, '""') + '"').join(','))
      .join('\n');
  const out = path.join(__dirname, 'catbox_urls.csv');
  fs.writeFileSync(out, csv);
  console.log('\nSaved -> ' + out);
})().catch((e) => {
  console.error('\nFATAL:', e.message);
  process.exit(1);
});
