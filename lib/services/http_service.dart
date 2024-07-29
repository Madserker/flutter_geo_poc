import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  final String baseUrl = 'https://inspect-qa.cotecna.com/api';
  late String userToken;

  static final HttpService _instance = HttpService._internal();
  
  HttpService._internal();

  factory HttpService(){return _instance;}

  setUserToken(String token) {
    userToken = token;
  }

  Future<dynamic> getRequest(String endpoint,  Map<String, String>? headers) async {
    try{
      Map<String, String> callHeaders = getHeaders(headers);
      final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: callHeaders);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e){
      print(e);
    }
    
  }

  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data');
    }
  }

  Map<String, String> getHeaders(Map<String, String>? headers) {
    final allHeaders = {
      'Authorization' : 'Bearer $userToken',
      'RequesterApp' : 'android',
      'AppVersion' : '9.2.0',
    };
    if (headers != null) {
      allHeaders.addAll(headers);
    }
    return allHeaders;
	}
}