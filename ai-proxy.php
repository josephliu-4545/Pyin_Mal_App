<?php
/**
 * ai-proxy.php — Pyin Mal AI Proxy
 *
 * Upload this file to the root of your OpenCart server.
 * Access it at: https://tachatnhate.xo.je/ai-proxy.php
 *
 * The Flutter app sends images here; this script calls Groq on the server
 * side (server is not in Myanmar, so api.groq.com is reachable).
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// ── Config ────────────────────────────────────────────────────────────────────
// Paste your Groq API key here (from https://console.groq.com/keys)
// DO NOT commit the actual key to git!
define('GROQ_API_KEY', getenv('GROQ_API_KEY') ?: 'YOUR_API_KEY_HERE');
define('GROQ_MODEL',   'meta-llama/llama-4-scout-17b-16e-instruct');
// ─────────────────────────────────────────────────────────────────────────────

$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON body']);
    exit;
}

$imageBase64     = $input['imageBase64']     ?? '';
$productsContext = $input['productsContext'] ?? '';
$promptHeader    = $input['promptHeader']    ?? '';
$promptFooter    = $input['promptFooter']    ?? '';

if (empty($imageBase64)) {
    http_response_code(400);
    echo json_encode(['error' => 'imageBase64 is required']);
    exit;
}

$fullPrompt = $promptHeader . $productsContext . $promptFooter;

$payload = json_encode([
    'model'           => GROQ_MODEL,
    'response_format' => ['type' => 'json_object'],
    'messages'        => [[
        'role'    => 'user',
        'content' => [
            [
                'type'      => 'image_url',
                'image_url' => ['url' => 'data:image/jpeg;base64,' . $imageBase64],
            ],
            [
                'type' => 'text',
                'text' => $fullPrompt,
            ],
        ],
    ]],
]);

$ch = curl_init('https://api.groq.com/openai/v1/chat/completions');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_TIMEOUT        => 30,
    CURLOPT_HTTPHEADER     => [
        'Authorization: Bearer ' . GROQ_API_KEY,
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS     => $payload,
    CURLOPT_SSL_VERIFYPEER => true,
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlErr  = curl_error($ch);
curl_close($ch);

if ($curlErr) {
    http_response_code(502);
    echo json_encode(['error' => 'cURL error: ' . $curlErr]);
    exit;
}

if ($httpCode !== 200) {
    http_response_code(502);
    echo json_encode(['error' => 'Groq returned ' . $httpCode, 'body' => $response]);
    exit;
}

$data = json_decode($response, true);
$text = $data['choices'][0]['message']['content'] ?? '';
echo json_encode(['text' => $text]);
