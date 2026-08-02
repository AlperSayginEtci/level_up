import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class NutritionResult {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String foodName;

  NutritionResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.foodName,
  });

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    return NutritionResult(
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      foodName: json['foodName'] ?? 'Unknown Food',
    );
  }
}

class AiNutritionService {
  static Future<NutritionResult?> analyzeFoodImage(String apiKey, File imageFile) async {
    final cleanApiKey = apiKey.trim();
    if (cleanApiKey.isEmpty) {
      throw Exception('API Key is empty.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    
    String mimeType = 'image/jpeg';
    final ext = imageFile.path.split('.').last.toLowerCase();
    if (ext == 'png') mimeType = 'image/png';
    else if (ext == 'webp') mimeType = 'image/webp';
    else if (ext == 'heic') mimeType = 'image/heic';

    final dio = Dio();
    // Use the latest 2026 models based on the API key's available models
    final models = ['gemini-2.5-flash', 'gemini-flash-latest', 'gemini-2.0-flash'];
    List<String> errors = [];

    for (String model in models) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanApiKey';
        
        final payload = {
          "contents": [
            {
              "parts": [
                {"text": "You are an expert nutritionist. Analyze this image and estimate the macronutrients and calories. Assume an average serving size if it's not clear. Return ONLY a valid JSON object with keys: calories (int), protein (int), carbs (int), fat (int), foodName (string). Do not return markdown, only pure JSON."},
                {
                  "inlineData": {
                    "mimeType": mimeType,
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json"
          }
        };

        final response = await dio.post(url, data: payload, options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true, // Don't throw on error status yet
        ));

        if (response.statusCode == 200) {
          final data = response.data;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              String text = parts[0]['text'] ?? '';
              text = text.trim();
              if (text.startsWith('```json')) text = text.substring(7);
              else if (text.startsWith('```')) text = text.substring(3);
              if (text.endsWith('```')) text = text.substring(0, text.length - 3);
              text = text.trim();
              
              final jsonMap = jsonDecode(text);
              return NutritionResult.fromJson(jsonMap);
            }
          }
          throw Exception('Empty response from model $model');
        } else {
          final errorMsg = response.data.toString();
          errors.add('$model HTTP ${response.statusCode}: $errorMsg');
          debugPrint('Model $model failed: $errorMsg');
          // If it's a 400 Bad Request about the API key, no need to try other models
          if (response.statusCode == 400 && errorMsg.contains('API key')) {
             throw Exception('Invalid API Key: $errorMsg');
          }
        }
      } catch (e) {
        errors.add('$model Exception: $e');
      }
    }
    
    // If we reach here, all models failed. Let's fetch the list of available models to see what the user actually has!
    String availableModelsInfo = "Could not fetch available models.";
    try {
      final listUrl = 'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanApiKey';
      final listResponse = await dio.get(listUrl, options: Options(validateStatus: (status) => true));
      if (listResponse.statusCode == 200) {
        final modelsList = listResponse.data['models'] as List?;
        if (modelsList != null) {
          final modelNames = modelsList.map((m) => m['name'].toString().replaceAll('models/', '')).toList();
          availableModelsInfo = "AVAILABLE MODELS FOR YOUR KEY:\n" + modelNames.join(', ');
        }
      } else {
        availableModelsInfo = "ListModels failed: ${listResponse.statusCode}";
      }
    } catch (e) {
      availableModelsInfo = "ListModels exception: $e";
    }

    throw Exception('All direct HTTP calls failed.\n\n$availableModelsInfo\n\nErrors:\n' + errors.join('\n\n'));
  }
}
