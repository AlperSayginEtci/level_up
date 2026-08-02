import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

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
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'calories': Schema.integer(description: 'Estimated total calories in kcal'),
              'protein': Schema.integer(description: 'Estimated protein in grams'),
              'carbs': Schema.integer(description: 'Estimated carbohydrates in grams'),
              'fat': Schema.integer(description: 'Estimated fat in grams'),
              'foodName': Schema.string(description: 'Name of the identified food'),
            },
            requiredProperties: ['calories', 'protein', 'carbs', 'fat', 'foodName'],
          ),
        ),
      );

      final imageBytes = await imageFile.readAsBytes();
      final prompt = TextPart("You are an expert nutritionist. Analyze this image and estimate the macronutrients and calories. Assume an average serving size if it's not clear. Return ONLY a valid JSON object matching the requested schema.");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text != null) {
        final jsonMap = jsonDecode(response.text!);
        return NutritionResult.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('AI Nutrition Error: $e');
    }
    return null;
  }
}
