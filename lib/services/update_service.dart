import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // Bu URL'yi daha sonra kendi version.json'ı barındırdığın yerle değiştireceksin.
  // Örneğin: Firebase Storage linki veya bir GitHub Gist raw linki.
  static const String versionCheckUrl = "https://raw.githubusercontent.com/AlperSayginEtci/level_up/main/version.json";
  
  static Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final dio = Dio();
      // Yükleme hızı için timeout eklenebilir
      final response = await dio.get(versionCheckUrl, options: Options(
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 500,
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.data.toString());
        final latestVersion = data['version'] as String;
        final downloadUrl = data['url'] as String;
        final releaseNotes = data['notes'] as String? ?? "System Upgrade Available.";
        
        if (_isNewerVersion(currentVersion, latestVersion)) {
          return {
            'latestVersion': latestVersion,
            'downloadUrl': downloadUrl,
            'notes': releaseNotes,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint("Güncelleme kontrol hatası: $e");
      return null;
    }
  }
  
  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      List<int> curr = currentVersion.split('.').map(int.parse).toList();
      List<int> latest = latestVersion.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        int c = i < curr.length ? curr[i] : 0;
        int l = i < latest.length ? latest[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
