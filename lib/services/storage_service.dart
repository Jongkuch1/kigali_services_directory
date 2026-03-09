import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Cloudinary-backed image storage (free tier, no credit card required).
///
/// Setup (one-time):
///   1. Create a free account at https://cloudinary.com
///   2. Copy your Cloud Name from the dashboard homepage
///   3. Go to Settings → Upload → Upload presets → Add upload preset
///      • Set Signing Mode to "Unsigned"
///      • Save and copy the preset name
///   4. Replace _cloudName and _uploadPreset below with your values
class StorageService {
  static const _cloudName = 'YOUR_CLOUD_NAME'; // e.g. 'dxyz123abc'
  static const _uploadPreset = 'YOUR_UNSIGNED_PRESET'; // e.g. 'kigali_listings'

  /// Uploads [imageFile] to Cloudinary and returns the HTTPS download URL.
  Future<String> uploadListingImage(String uid, File imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'listings/$uid'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Image upload failed (HTTP ${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  /// Cloudinary delete requires the API secret and must be done server-side.
  /// Old images on the free tier are auto-purged; manage them via the dashboard.
  Future<void> deleteImage(String imageUrl) async {}
}
