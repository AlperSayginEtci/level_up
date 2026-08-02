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
    debugPrint("Received message from WearOS: ${message.path}");
    
    if (message.path == "/quest_completed") {
      final String questId = utf8.decode(message.data);
      _completeQuestLocally(questId);
    } 
    else if (message.path == "/quest_progress") {
      final String jsonStr = utf8.decode(message.data);
      final data = jsonDecode(jsonStr);
      _updateQuestProgressLocally(data['id'], data['progress']);
    }
    else if (message.path == "/sync_quests") {
      final String jsonStr = utf8.decode(message.data);
      _updateLocalQuestsFromSync(jsonStr);
    }
    else if (message.path == "/sync_stats") {
      final String jsonStr = utf8.decode(message.data);
      _updateLocalStatsFromSync(jsonStr);
    }
  }

  static Future<void> _updateLocalStatsFromSync(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr);
      final currentStats = DatabaseService.getPlayerStats();
      
      // Update local watch stats
      final updatedStats = currentStats.copyWith(
        level: data['level'],
        exp: data['exp'],
      );
      
      await DatabaseService.savePlayerStats(updatedStats);
      
      // We also might want to notify UI.
      if (onSyncDataReceived != null) {
        onSyncDataReceived!();
      }
    } catch (e) {
      debugPrint("Error syncing stats to watch: $e");
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
          bool questChanged = false;
          
          if (localQ.isCompleted != item['isCompleted']) {
            if (item['isCompleted'] == true) {
               localQ.forceComplete();
            } else {
               localQ.resetDaily();
            }
            questChanged = true;
          }
          
          if (item['currentProgress'] != null && localQ.currentProgress != item['currentProgress']) {
            int progressDiff = item['currentProgress'] - localQ.currentProgress;
            if (progressDiff > 0) {
               localQ.addProgress(progressDiff);
               questChanged = true;
            }
          }
          
          if (questChanged) {
            await DatabaseService.saveQuest(localQ);
            changed = true;
          }
        }
      }
      
      if (changed && onSyncDataReceived != null) {
        onSyncDataReceived!();
      }
    } catch (e) {
      debugPrint("Error syncing quests to watch: $e");
    }
  }

  static Future<void> _updateQuestProgressLocally(String questId, int progressToAdd) async {
    final quests = DatabaseService.getAllQuests();
    final questIndex = quests.indexWhere((q) => q.id == questId);
    
    if (questIndex != -1) {
      final quest = quests[questIndex];
      if (!quest.isCompleted) {
        quest.addProgress(progressToAdd);
        await DatabaseService.saveQuest(quest);
        if (onSyncDataReceived != null) {
          onSyncDataReceived!();
        }
      }
    }
  }

  static Future<void> _completeQuestLocally(String questId) async {
    final quests = DatabaseService.getAllQuests();
    final questIndex = quests.indexWhere((q) => q.id == questId);
    
    if (questIndex != -1) {
      final quest = quests[questIndex];
      if (!quest.isCompleted) {
        quest.addProgress(quest.targetProgress);
        await DatabaseService.saveQuest(quest);
        if (onSyncDataReceived != null) {
          onSyncDataReceived!();
        }
      }
    }
  }

  static Future<void> sendQuestsToWatch(List<Quest> quests) async {
    if (!_isInitialized || _wearOsConnectivity == null) return;
    
    try {
      final connectedDevices = await _wearOsConnectivity!.getConnectedDevices();
      if (connectedDevices.isEmpty) return;

      final List<Map<String, dynamic>> simplifiedQuests = quests.map((q) => {
        'id': q.id,
        'title': q.title,
        'isCompleted': q.isCompleted,
        'difficulty': q.difficulty.name,
        'currentProgress': q.currentProgress,
        'targetProgress': q.targetProgress,
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
      debugPrint("SyncService Send Error: $e");
    }
  }
  
  static Future<void> sendPlayerStatsToWatch(int level, int exp) async {
    if (!_isInitialized || _wearOsConnectivity == null) return;
    
    try {
      final connectedDevices = await _wearOsConnectivity!.getConnectedDevices();
      if (connectedDevices.isEmpty) return;

      final Map<String, dynamic> stats = {
        'level': level,
        'exp': exp,
      };

      final String jsonStr = jsonEncode(stats);
      final Uint8List data = Uint8List.fromList(utf8.encode(jsonStr));

      for (var device in connectedDevices) {
        await _wearOsConnectivity!.sendMessage(
          data,
          deviceId: device.id,
          path: "/sync_stats",
        );
      }
    } catch (e) {
      debugPrint("SyncService Stats Send Error: $e");
    }
  }
  
  static Future<void> sendProgressToPhone(String questId, int progressToAdd) async {
    if (!_isInitialized || _wearOsConnectivity == null) return;
    
    try {
      final connectedDevices = await _wearOsConnectivity!.getConnectedDevices();
      if (connectedDevices.isEmpty) return;

      final Map<String, dynamic> payload = {
        'id': questId,
        'progress': progressToAdd,
      };

      final String jsonStr = jsonEncode(payload);
      final Uint8List data = Uint8List.fromList(utf8.encode(jsonStr));

      for (var device in connectedDevices) {
        await _wearOsConnectivity!.sendMessage(
          data,
          deviceId: device.id,
          path: "/quest_progress",
        );
      }
    } catch (e) {
      debugPrint("SyncService Send Progress Error: $e");
    }
  }
}
