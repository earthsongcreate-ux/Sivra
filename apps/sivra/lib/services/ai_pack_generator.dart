import 'dart:convert';
import 'dart:io';

import '../models/daily_pack.dart';
import '../models/drill_item.dart';
import '../models/learning_profile.dart';

class AiPackGenerator {
  final Uri? endpoint;
  final String authToken;
  final HttpClient Function() httpClientFactory;

  const AiPackGenerator({
    required this.endpoint,
    this.authToken = '',
    this.httpClientFactory = _defaultHttpClient,
  });

  factory AiPackGenerator.fromEnvironment() {
    const endpointValue = String.fromEnvironment('SIVRA_AI_PACK_ENDPOINT');
    const authToken = String.fromEnvironment('SIVRA_AI_PACK_TOKEN');

    return AiPackGenerator(
      endpoint: endpointValue.isEmpty ? null : Uri.tryParse(endpointValue),
      authToken: authToken,
    );
  }

  bool get isConfigured =>
      endpoint != null && endpoint!.hasScheme && endpoint!.host.isNotEmpty;

  Future<DailyPack?> generate({
    required String uid,
    required String dayId,
    required List<String> focusAreas,
    LearningProfile? learningProfile,
  }) async {
    final target = endpoint;
    if (target == null || !isConfigured) {
      return null;
    }

    final client = httpClientFactory();
    try {
      final request = await client.postUrl(target);
      request.headers.contentType = ContentType.json;
      if (authToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $authToken',
        );
      }

      request.write(
        jsonEncode(<String, dynamic>{
          'uid': uid,
          'dayId': dayId,
          'focusAreas': focusAreas,
          if (learningProfile != null)
            'learningProfile': learningProfile.toMap(),
          'schemaVersion': 1,
        }),
      );

      final response = await request.close();
      final body = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final packData = decoded['pack'] is Map<String, dynamic>
          ? decoded['pack'] as Map<String, dynamic>
          : decoded;

      return _packFromAiResponse(
        data: packData,
        dayId: dayId,
        fallbackFocusAreas: focusAreas,
      );
    } on FormatException {
      return null;
    } on IOException {
      return null;
    } finally {
      client.close();
    }
  }

  DailyPack _packFromAiResponse({
    required Map<String, dynamic> data,
    required String dayId,
    required List<String> fallbackFocusAreas,
  }) {
    final rawItems = data['items'];
    final rawFocusAreas = data['focusAreas'];

    return DailyPack(
      dayId: data['dayId'] is String ? data['dayId'] as String : dayId,
      focusAreas: rawFocusAreas is List
          ? rawFocusAreas.whereType<String>().toList()
          : fallbackFocusAreas,
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(DrillItem.fromMap)
                .toList()
          : const <DrillItem>[],
      generator: data['generator'] is String
          ? data['generator'] as String
          : 'ai_endpoint_v1',
    );
  }
}

HttpClient _defaultHttpClient() => HttpClient();
