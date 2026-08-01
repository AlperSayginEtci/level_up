import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/system_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoginMode = true; // true = Login, false = Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('System requires Email and Password inputs.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await AuthService.signInWithEmail(email, password);
      } else {
        await AuthService.registerWithEmail(email, password);
      }
      if (mounted) {
        await context.read<PlayerProgressAndStatsController>().syncWithCloudOnLogin();
      }
      // If successful, main.dart's authStateChanges will automatically 
      // navigate the user to the MainLayout. We don't need to push manually.
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Authentication failed.');
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) {
        // User canceled
        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        if (mounted) {
          await context.read<PlayerProgressAndStatsController>().syncWithCloudOnLogin();
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google Sign-In failed.');
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Google Sign-In error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default theme colors for System Awakening
    final primaryColor = AppTheme.getPrimaryColor(false);
    final darkColor = AppTheme.getDarkColor(false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SystemBackground(
        isShadowMonarch: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLoginMode ? '[ SYSTEM LOGIN ]' : '[ HUNTER REGISTRATION ]',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 22,
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
                    const SizedBox(height: 32),
                    
                    // Email Field
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: primaryColor.withValues(alpha: 0.7)),
                        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: primaryColor.withValues(alpha: 0.7)),
                        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 10,
                          shadowColor: primaryColor,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isLoginMode ? 'AWAKEN (LOGIN)' : 'REGISTER',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Switch Mode
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(
                        _isLoginMode
                            ? 'No Account? Register as a New Hunter'
                            : 'Already a Hunter? Proceed to System',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    
                    const Divider(color: Colors.white24, height: 32),
                    
                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _googleSignIn,
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                          height: 24,
                        ),
                        label: const Text(
                          'SIGN IN WITH GOOGLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
