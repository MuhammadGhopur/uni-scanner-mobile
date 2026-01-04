import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSheetService {
  final String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbwh-0gDec192F9u28sLtVpGzyrZccd8T8665MXqV4wzs9rwtLeJkPmobVKReTDM4iJn/exec';

  Future<bool> sendScannedData({
    required String poNumber,
    required String sku,
    required String width,
    required String size,
    required String right,
    required String left,
    required String qty,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'poNumber': poNumber.replaceAll(RegExp(r'"'), ''), // Remove quotes
          'sku': sku.replaceAll(RegExp(r'"'), ''), // Remove quotes
          'width': width,
          'size': size,
          'right': right,
          'left': left,
          'qty': qty,
        }),
      );

      // Consider 200 (OK) and 302 (Found/Redirect) as success, as Apps Script often redirects.
      if (response.statusCode == 200 || response.statusCode == 302) {
        // Additionally, try to parse the response body for a specific success status
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody['status'] == 'success') {
            return true;
          }
        } catch (e) {
          // If response body is not JSON or doesn't contain 'status', but status code is 200/302,
          // we still consider it a potential success.
          print('Warning: Could not parse Google Sheet response, but status code was ${response.statusCode}. Error: $e');
          return true; // Assume success if status code is good, even if JSON is malformed
        }
      }

      print('Gagal mengirim data ke Google Sheet: ${response.statusCode}');
      print('Response body: ${response.body}');
      return false;
    } catch (e) {
      print('Error saat mengirim data ke Google Sheet: $e');
      return false;
    }
  }
}
