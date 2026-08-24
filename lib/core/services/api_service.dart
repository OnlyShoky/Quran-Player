import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reciter.dart';

class ApiService {
  static const String _baseUrl = 'https://mp3quran.net/api/v3';

  Future<List<Reciter>> fetchReciters() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/reciters?language=eng'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recitersList = data['reciters'] as List;

        return recitersList
            .map((json) => Reciter.fromJson(json))
            .where((r) => r.serverUrl.isNotEmpty) // Only include if they have a valid server URL
            .toList();
      } else {
        throw Exception('Failed to load reciters');
      }
    } catch (e) {
      // Return empty list on failure for now, let provider handle error state if needed
      return [];
    }
  }
}
