import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:level_up/models/quest.dart';
import 'package:level_up/services/database_service.dart';

class SyncService {
  static FlutterWearOsConnectivity? _wearOsConnectivity;
  static bool _isInitialized = false;
  static VoidCallback? onSyncDataReceived;

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
    
    if (message.path == "/quest_completed") {
      final String questId = utf8.decode(message.data);
      _completeQuestLocally(questId);
    } 
    else if (message.path == "/sync_quests") {
      // Saat, telefondan gelen görev listesini alıyor
      final String jsonStr = utf8.decode(message.data);
      _updateLocalQuestsFromSync(jsonStr);
    }
  }

  static Future<void> _updateLocalQuestsFromSync(String jsonStr) async {
    try {
      final List<dynamic> data = jsonDecode(jsonStr);
      final localQuests = DatabaseService.getAllQuests();
      bool changed = false;

      for (var item in data) {
        final qIndex = localQuests.indexWhere((q) => q.id == item['id']);
        if (qIndex != -1) {
          final localQ = localQuests[qIndex];
          if (localQ.isCompleted != item['isCompleted']) {
            if (item['isCompleted'] == true) {
               localQ.forceComplete();
            } else {
               localQ.resetDaily();
            }
            await DatabaseService.saveQuest(localQ);
            changed = true;
          }
        }
      }
      
      if (changed && onSyncDataReceived != null) {
        onSyncDataReceived!();
      }
      
      // Not: Ekrana yansıması için state manager'ın reload yapması gerek.
      // Basitçe reload tetiklemek için bir EventBus veya callback eklenebilir,
      // veya Provider yapısı gereği UI her saniye güncelleniyorsa yeterli olabilir.
    } catch (e) {
      debugPrint("Error syncing quests to watch: \$e");
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
