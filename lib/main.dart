import 'package:core_vision/screens/daily_stream_screen.dart';
import 'package:core_vision/screens/savora_welcome_screen.dart';
import 'package:core_vision/theme/core_theme.dart';
import 'package:flutter/material.dart';
import 'package:core_vision/data/data_service.dart';
import 'package:core_vision/data/settings_service.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isLocked = false;
  bool _isAuthenticating = false;
  final LocalAuthentication auth = LocalAuthentication();
  AppLifecycleState? _lastLifecycleState;
  bool _wasPaused = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Initialize Services safely
    try {
      await DataService().init();
    } catch (e) {
      debugPrint("DataService failed: $e");
    }

    try {
      await SettingsService().init();
    } catch (e) {
      debugPrint("SettingsService failed: $e");
    }

    // 2. Check Lock State (only if settings loaded)
    _checkInitialLock();

    // 3. Update UI to show App
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPaused && !_isAuthenticating) {
        _checkBiometricsOnResume();
      }
      _wasPaused = false; 
    }
    _lastLifecycleState = state;
  }

  Future<void> _checkInitialLock() async {
    if (SettingsService().biometricEnabled.value) {
      setState(() => _isLocked = true);
      _authenticate();
    }
  }

  Future<void> _checkBiometricsOnResume() async {
    if (SettingsService().biometricEnabled.value && !_isLocked) {
      setState(() => _isLocked = true);
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() => _isAuthenticating = true);
    bool authenticated = false;
    
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Unlock Savora',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      
      if (authenticated) {
        setState(() => _isLocked = false);
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Authentication error: $e"), duration: Duration(seconds: 2))
         );
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 300)); 
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CoreTheme.lightTheme,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8B5CF6).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset('assets/images/savora_logo_clean.png'),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Savora',
      debugShowCheckedModeBanner: false,
      theme: CoreTheme.lightTheme,
      home: ValueListenableBuilder<bool>(
        valueListenable: SettingsService().hasSeenWelcome,
        builder: (context, hasSeen, _) {
          return Stack(
            children: [
              hasSeen ? DailyStreamScreen() : SavoraWelcomeScreen(),
              
              if (_isLocked)
                Stack(
                  children: [
                    // 1. BLUR EFFECT
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child: Container(
                          color: Colors.white.withOpacity(0.6), 
                        ),
                      ),
                    ),
                    
                    // 2. UNLOCK CONTENT
                    Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                  boxShadow: [
                                    BoxShadow(color: Color(0xFF8B5CF6).withOpacity(0.2), blurRadius: 30, offset: Offset(0, 10)),
                                  ],
                                ),
                                child: Icon(Icons.lock_rounded, size: 48, color: Colors.white),
                              ),
                              SizedBox(height: 32),
                              Text(
                                "Savora Locked",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A), 
                                  shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                                ),
                              ),
                              SizedBox(height: 48),
                               ElevatedButton.icon(
                                onPressed: _authenticate,
                                icon: Icon(Icons.fingerprint_rounded, color: Colors.white),
                                label: Text("Tap to Unlock", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8B5CF6),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                   shadowColor: Color(0xFF8B5CF6).withOpacity(0.5),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
