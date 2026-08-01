import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/player_state_manager.dart';

class SystemUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;

  const SystemUpdateDialog({super.key, required this.updateInfo});

  @override
  State<SystemUpdateDialog> createState() => _SystemUpdateDialogState();
}

class _SystemUpdateDialogState extends State<SystemUpdateDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String downloadStatus = "";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _startDownload() async {
    setState(() {
      isDownloading = true;
      downloadStatus = "Connecting to System Server...";
    });
    
    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory(); // Android only
      final savePath = "${dir?.path}/levelup_update.apk";
      
      await dio.download(
        widget.updateInfo['downloadUrl'], 
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
              downloadStatus = "Downloading... ${((downloadProgress * 100).toStringAsFixed(0))}%";
            });
          }
        },
      );
      
      setState(() {
        downloadStatus = "Download Complete. Initiating Install...";
      });
      
      // Open APK using open_file
      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done) {
        setState(() {
          downloadStatus = "Failed to launch installer. Open file manually in: $savePath";
        });
      } else {
        // İndirme ve kurulum açıldıktan sonra popup'ı kapatabiliriz.
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        downloadStatus = "Download Failed: $e";
        isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final isShadowMonarch = playerController.isShadowMonarchThemeActive;
    final primaryColor = AppTheme.getPrimaryColor(isShadowMonarch);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppTheme.getDarkColor(isShadowMonarch).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Text(
                    '[ SYSTEM UPGRADE ]',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.system_update_alt_rounded,
                      color: primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A new version of the System is available.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Version: ${widget.updateInfo['latestVersion']}",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.updateInfo['notes'] ?? "",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (isDownloading)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: downloadProgress,
                            backgroundColor: Colors.grey[800],
                            color: primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            downloadStatus,
                            style: TextStyle(color: primaryColor, fontSize: 12),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('LATER', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: _startDownload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('UPGRADE NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
