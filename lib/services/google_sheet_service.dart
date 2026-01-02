import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uni_scanner/utils/constants.dart';

class GoogleSheetService {
  Future<http.Response> postData(Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse(GOOGLE_SHEET_URL),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
  }
}

