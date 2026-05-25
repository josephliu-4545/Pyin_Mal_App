import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class NanoBananaApiService {
  // TODO: Replace with secure method of fetching API key (e.g. flutter_dotenv or Firebase)
  static const String _apiKey = '84dee9e4************************24a9'; // Your API key goes here
  static const String _endpoint = 'https://api.nanobananaapi.ai/api/v1/nanobanana/generate';

  /// Generates a try-on image by sending the user's photo and the clothes photo.
  /// Note: The exact JSON fields might need adjustment based on Nano Banana's exact spec.
  static Future<String?> generateTryOnImage({
    required File userPhoto,
    required File clothesPhoto,
  }) async {
    try {
      // 1. Convert files to Base64
      final userPhotoBytes = await userPhoto.readAsBytes();
      final clothesPhotoBytes = await clothesPhoto.readAsBytes();
      
      final userPhotoBase64 = base64Encode(userPhotoBytes);
      final clothesPhotoBase64 = base64Encode(clothesPhotoBytes);

      // 2. Prepare the payload (assuming standard image generation fields)
      final payload = {
        'model': 'nanobanana-try-on', // or the specific model ID required
        'prompt': 'Virtual try-on of this clothing on this person.',
        'image': userPhotoBase64,
        'reference_image': clothesPhotoBase64,
      };

      // 3. Send HTTP POST request
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(payload),
      );

      // 4. Handle Response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Return the generated image URL (adjust according to actual response structure)
        return data['data']?['url'] ?? data['output_url'] ?? data['url'];
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in generateTryOnImage: $e');
      return null;
    }
  }
}
