import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:level_up/models/quest.dart';
import 'package:level_up/services/database_service.dart';

class SyncService {
  static FlutterWearOsConnectivity? _wearOsConnectivity;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (kIsWeb) return; // Wear OS works only on Android
    
    try {
      _wearOsConnectivity = FlutterWearOsConnectivity();
      _isInitialized = true;
      _wearOsConnectivity!.configureWearableAPI();
      
      // Saat veya telefondan gelen mesajları dinle
      _wearOsConnectivity!.messageReceived().listen((WearOSMessage message) {
        _handleIncomingMessage(message);
      });
      
    } catch (e) {
      debugPrint("SyncService Init Error: \$e");
    }
  }

  static void _handleIncomingMessage(WearOSMessage message) {
    debugPrint("Received message from WearOS: \${message.path}");
    
    // Saat üzerinden bir görev tamamlandığında:
    if (message.path == "/quest_completed") {
      final String questId = utf8.decode(message.data);
      _completeQuestLocally(questId);
    }
  }

  static Future<void> _completeQuestLocally(String questId) async {
    final quests = DatabaseService.getAllQuests();
    final questIndex = quests.indexWhere((q) => q.id == questId);
    
    if (questIndex != -1) {
      final quest = quests[questIndex];
      if (!quest.isCompleted) {
        // İlerlemeyi artır
        quest.addProgress(quest.targetProgress);
        await DatabaseService.saveQuest(quest);
        // Not: State manager'ın da güncellenmesi için Provider dinleyicilerini tetiklemek gerek.
        // Bu yapı, genel mimariye göre Controller'da ele alınmalıdır.
      }
    }
  }

  // Telefonda bir görev durumu değiştiğinde bunu saate gönder
  static Future<void> sendQuestsToWatch(List<Quest> quests) async {
    if (!_isInitialized || _wearOsConnectivity == null) return;
    
    try {
      final connectedDevices = await _wearOsConnectivity!.getConnectedDevices();
      if (connectedDevices.isEmpty) return;

      // Görevleri sadeleştirip JSON yapıyoruz (Sadece ID, Title ve Completed durumu)
      final List<Map<String, dynamic>> simplifiedQuests = quests.map((q) => {
        'id': q.id,
        'title': q.title,
        'isCompleted': q.isCompleted,
        'difficulty': q.difficulty.name,
      }).toList();

      final String jsonStr = jsonEncode(simplifiedQuests);
      final Uint8List data = Uint8List.fromList(utf8.encode(jsonStr));

      for (var device in connectedDevices) {
        await _wearOsConnectivity!.sendMessage(
          data,
          deviceId: device.id,
          path: "/sync_quests",
        );
      }
    } catch (e) {
      debugPrint("SyncService Send Error: \$e");
    }
  }
}
