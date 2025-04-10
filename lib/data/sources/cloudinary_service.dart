import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = 'deiaeowiq'; // 👉 o teu Cloud Name
  static const String uploadPreset =
      'FotosDePerfil'; // 👉 o teu preset (unsigned)

  static Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..fields['folder'] = folder ?? 'uploads'
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final jsonData = json.decode(responseData.body);
        return jsonData['secure_url'];
      } else {
        print('❌ Erro Cloudinary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exceção no upload Cloudinary: $e');
      return null;
    }
  }
}
