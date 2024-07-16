import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class UploadApiImage {
  Future<dynamic> uploadImage(Uint8List bytes, String fileName) async {
    Uri url = Uri.parse("http://127.0.0.1:5000/upload/img");
    var request = http.MultipartRequest("POST", url);
    var myFile = http.MultipartFile.fromBytes(
      "file",
      bytes,
      filename: fileName,
    );
    request.files.add(myFile);
    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      var responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
