import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/news.dart';
import '../../../core/config/app_config.dart';

class NewsService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  Future<List<News>> getNews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/news'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => News.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  Future<List<News>> createNews({
    required String orgId,
    required String title,
    required String description,
    required File file,
  }) async {
    // try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/news'));
      
      request.fields['orgId'] = orgId;
      request.fields['title'] = title;
      request.fields['description'] = description;
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'png'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => News.fromJson(json)).toList();
      } else {
        throw Exception('Failed to create news');
      }
    // } catch (e) {
    //   throw Exception('Error creating news: $e');
    // }
  }

  Future<void> deleteNews(String newsId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/news/$newsId'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete news');
      }
    } catch (e) {
      throw Exception('Error deleting news: $e');
    }
  }
} 