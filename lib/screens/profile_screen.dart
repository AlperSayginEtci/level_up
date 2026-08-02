import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:level_up/services/auth_service.dart';
import '../providers/player_state_manager.dart';
import '../theme/app_theme.dart';
import '../services/cloud_sync_service.dart';
import 'quest_history_screen.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();

    final isShadowMonarch = playerController.isShadowMonarchThemeActive;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'System Account',
          style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (playerController.isShadowMonarchThemeUnlocked)
            IconButton(
              icon: Icon(
                Icons.dark_mode,
                color: AppTheme.getPrimaryColor(isShadowMonarch),
              ),
              onPressed: () {
                playerController.toggleShadowMonarchTheme();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(context, playerController),
              // Quest Records Section
              Container(
                decoration: AppTheme.systemCardDecoration(isShadowMonarch),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(Icons.history, color: AppTheme.getPrimaryColor(isShadowMonarch), size: 32),
                  title: Text(
                    'View Quest History',
                    style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${playerController.availableQuests.where((q) => q.completionCount > 0).length} tracked quests',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.getPrimaryColor(isShadowMonarch).withValues(alpha: 0.5), size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuestHistoryScreen()),
                    );
                  },
                ),
              ),

              // Achievements / Ranks Section
              Container(
                decoration: AppTheme.systemCardDecoration(isShadowMonarch),
                margin: const EdgeInsets.only(bottom: 24),
                child: ListTile(
                  leading: Icon(Icons.stars, color: Colors.yellowAccent.withValues(alpha: 0.8), size: 32),
                  title: Text(
                    'View Hunter Ranks',
                    style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${playerController.achievements.where((a) => a.isUnlocked).length} / ${playerController.achievements.length} Unlocked',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.getPrimaryColor(isShadowMonarch).withValues(alpha: 0.5), size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                    );
                  },
                ),
              ),

              // Player Metrics Section
              Container(
                decoration: AppTheme.systemCardDecoration(isShadowMonarch),
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_weight, color: AppTheme.getPrimaryColor(isShadowMonarch), size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Physical Metrics',
                            style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.edit, color: AppTheme.getPrimaryColor(isShadowMonarch)),
                            onPressed: () => _showEditMetricsDialog(context, playerController),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem('Age', '${playerController.playerAge}', isShadowMonarch),
                          _buildMetricItem('Height', '${playerController.playerHeight} cm', isShadowMonarch),
                          _buildMetricItem('Weight', '${playerController.playerWeight} kg', isShadowMonarch),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // System Settings Section
              Container(
                decoration: AppTheme.systemCardDecoration(isShadowMonarch),
                margin: const EdgeInsets.only(bottom: 24),
                child: ListTile(
                  leading: Icon(Icons.vpn_key, color: AppTheme.getPrimaryColor(isShadowMonarch), size: 32),
                  title: Text(
                    'System API Key (Gemini)',
                    style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    playerController.geminiApiKey != null && playerController.geminiApiKey!.isNotEmpty 
                        ? 'Configured' 
                        : 'Required for AI Food Scanner',
                    style: TextStyle(color: playerController.geminiApiKey != null && playerController.geminiApiKey!.isNotEmpty ? Colors.green : Colors.redAccent),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.getPrimaryColor(isShadowMonarch).withValues(alpha: 0.5), size: 16),
                  onTap: () => _showEditApiKeyDialog(context, playerController),
                ),
              ),

              // --- CLOUD SYNC SECTION ---
              Container(
                decoration: AppTheme.systemCardDecoration(isShadowMonarch),
                margin: const EdgeInsets.only(bottom: 32),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_sync, color: AppTheme.getPrimaryColor(isShadowMonarch), size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Data Center',
                            style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'All your progress is automatically synced with the System Cloud in real-time. Log in on any device to continue your journey.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildSettingTile(
                            icon: Icons.cloud_upload,
                            title: 'Cloud Sync: Backup (Device -> Cloud)',
                            color: AppTheme.getPrimaryColor(isShadowMonarch),
                            onTap: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Uploading to cloud...')),
                                );
                                await CloudSyncService.backupDataToCloud();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Backup successful!'), backgroundColor: Colors.green),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.cloud_download,
                            title: 'Cloud Sync: Restore (Cloud -> Device)',
                            color: AppTheme.getPrimaryColor(isShadowMonarch),
                            onTap: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Downloading from cloud...')),
                                );
                                await CloudSyncService.restoreDataFromCloud();
                                await context.read<PlayerProgressAndStatsController>().reloadFromStorage();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Restore successful!'), backgroundColor: Colors.green),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.logout,
                            title: 'SYSTEM LOGOUT',
                            color: Colors.redAccent,
                            onTap: () async {
                              try {
                                await AuthService.signOut();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  Widget _buildProfileHeader(BuildContext context, PlayerProgressAndStatsController controller) {
    final isShadowMonarch = controller.isShadowMonarchThemeActive;
    
    return Column(
      children: [
        _EasterEggAvatar(controller: controller),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              controller.playerName,
              style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.getPrimaryColor(isShadowMonarch).withValues(alpha: 0.6), size: 20),
              onPressed: () {
                _showEditNameDialog(context, controller);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: AppTheme.badgeDecoration(isShadowMonarch),
          child: Text(
            controller.currentRank.title,
            style: TextStyle(
              color: AppTheme.getPrimaryColor(isShadowMonarch),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
              shadows: [Shadow(color: AppTheme.getPrimaryColor(isShadowMonarch), blurRadius: 4)],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Total Quests Completed: ${controller.totalCompletedQuests}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        if (AuthService.currentUser != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'UID: ${AuthService.currentUser!.uid}',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ),
        const SizedBox(height: 24),
        Divider(color: AppTheme.getPrimaryColor(isShadowMonarch).withValues(alpha: 0.3)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, bool isShadowMonarch) {
    return Column(
      children: [
        Text(value, style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, PlayerProgressAndStatsController controller) {
    final TextEditingController nameController = TextEditingController(text: controller.playerName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.blueAccent, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Hunter Name', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent, width: 2)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  controller.updatePlayerProfile(newName);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditMetricsDialog(BuildContext context, PlayerProgressAndStatsController controller) {
    final ageCtrl = TextEditingController(text: controller.playerAge.toString());
    final heightCtrl = TextEditingController(text: controller.playerHeight.toString());
    final weightCtrl = TextEditingController(text: controller.playerWeight.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.deepPurple)),
          title: const Text('Update Metrics', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Age', labelStyle: TextStyle(color: Colors.grey)),
              ),
              TextField(
                controller: heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Height (cm)', labelStyle: TextStyle(color: Colors.grey)),
              ),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Weight (kg)', labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              const Text('* This will recalculate your daily macro goals automatically.', style: TextStyle(fontSize: 11, color: Colors.amber)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final age = int.tryParse(ageCtrl.text) ?? controller.playerAge;
                final height = double.tryParse(heightCtrl.text) ?? controller.playerHeight;
                final weight = double.tryParse(weightCtrl.text) ?? controller.playerWeight;
                controller.updatePlayerMetrics(age, weight, height);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  void _showEditApiKeyDialog(BuildContext context, PlayerProgressAndStatsController controller) {
    final keyCtrl = TextEditingController(text: controller.geminiApiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.deepPurple)),
          title: const Text('Gemini API Key', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Enter your API Key here', hintStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              const Text('Get yours at: https://aistudio.google.com/app/apikey', style: TextStyle(fontSize: 11, color: Colors.blueAccent)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                controller.updateGeminiApiKey(keyCtrl.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }
}

class _EasterEggAvatar extends StatefulWidget {
  final PlayerProgressAndStatsController controller;
  const _EasterEggAvatar({required this.controller});

  @override
  State<_EasterEggAvatar> createState() => _EasterEggAvatarState();
}

class _EasterEggAvatarState extends State<_EasterEggAvatar> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    final isShadowMonarch = widget.controller.isShadowMonarchThemeActive;
    final primary = AppTheme.getPrimaryColor(isShadowMonarch);

    return GestureDetector(
      onTap: () async {
        _tapCount++;
        if (_tapCount == 7) {
          if (!widget.controller.isShadowMonarchThemeUnlocked) {
            await widget.controller.unlockShadowMonarchTheme();
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.getDarkColor(true),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppTheme.shadowPurple, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'SYSTEM NOTIFICATION',
                    style: AppTheme.systemTextStyle(true, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'The Architect has been defeated.\n\nShadow Monarch Domain Unlocked.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('ARISE', style: AppTheme.systemTextStyle(true, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              );
            }
          } else {
             if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'You have already awakened, Monarch.',
                    style: AppTheme.systemTextStyle(isShadowMonarch),
                  ),
                  backgroundColor: AppTheme.getDarkColor(isShadowMonarch),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
          _tapCount = 0;
        }
      },
      onLongPress: () async {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 70,
        );
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final base64String = base64Encode(bytes);
          widget.controller.updateProfileImageBase64(base64String);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primary.withValues(alpha: 0.8),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.black45,
          backgroundImage: widget.controller.profileImageBase64 != null
              ? MemoryImage(base64Decode(widget.controller.profileImageBase64!))
              : null,
          child: widget.controller.profileImageBase64 == null
              ? Icon(Icons.person, size: 60, color: primary)
              : null,
        ),
      ),
    );
  }
}
