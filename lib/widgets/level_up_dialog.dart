import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../models/player_stats.dart';
import '../theme/app_theme.dart';

class LevelUpDialog extends StatefulWidget {
  final PlayerStats stats;

  const LevelUpDialog({super.key, required this.stats});

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerProgressAndStatsController>();
    final isShadowMonarch = controller.isShadowMonarchThemeActive;
    final primary = AppTheme.getPrimaryColor(isShadowMonarch);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32.0),
              padding: const EdgeInsets.all(24.0),
              decoration: AppTheme.systemCardDecoration(isShadowMonarch),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Title
                  Text(
                    'LEVEL UP!',
                    style: AppTheme.systemTextStyle(
                      isShadowMonarch,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                    ).copyWith(
                      color: primary,
                      shadows: [
                        Shadow(color: primary.withValues(alpha: 0.8), blurRadius: 10),
                        const Shadow(color: Colors.white, blurRadius: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  const Text(
                    'YOU HAVE REACHED A NEW LEVEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Level Number Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: AppTheme.badgeDecoration(isShadowMonarch),
                    child: Column(
                      children: [
                        Text(
                          'CURRENT LEVEL',
                          style: AppTheme.systemTextStyle(
                            isShadowMonarch,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ).copyWith(color: primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.stats.level}',
                          style: AppTheme.systemTextStyle(
                            isShadowMonarch,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ).copyWith(color: Colors.white, height: 1.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary.withValues(alpha: 0.2),
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'CONFIRM',
                        style: AppTheme.systemTextStyle(
                          isShadowMonarch,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
