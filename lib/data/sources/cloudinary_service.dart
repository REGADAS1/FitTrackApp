import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'deiaeowiq'; // o teu Cloud Name
  static const String uploadPreset = 'FotosDePerfil'; // o teu upload preset

  /// Upload a partir de bytes (Uint8List)
  static Future<String?> uploadBytes(Uint8List bytes, {String? folder}) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..fields['folder'] = folder ?? 'uploads'
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: 'image.jpg', // pode ser .gif ou .mp4 se for vídeo/gif
              ),
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
      print('❌ Exceção ao fazer upload: $e');
      return null;
    }
  }
}
