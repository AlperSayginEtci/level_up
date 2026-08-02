import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/system_background.dart';

class WearSyncScreen extends StatelessWidget {
  const WearSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.getPrimaryColor(false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SystemBackground(
        isShadowMonarch: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sync_rounded,
                size: 48,
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                '[ SYSTEM LINK ]',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: primaryColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Please AWAKEN (login) on your phone to synchronize your stats.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
