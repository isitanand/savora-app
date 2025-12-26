import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../data/settings_service.dart';
import '../main.dart'; // To navigate to MyApp or trigger rebuild

class SavoraWelcomeScreen extends StatefulWidget {
  const SavoraWelcomeScreen({super.key});

  @override
  State<SavoraWelcomeScreen> createState() => _SavoraWelcomeScreenState();
}

class _SavoraWelcomeScreenState extends State<SavoraWelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 2000),
       vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.6, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeWelcome() async {
    HapticFeedback.lightImpact();
    // Set Persistence - This triggers MyApp to switch to DailyStreamScreen via ValueListenableBuilder
    SettingsService().setHasSeenWelcome(true);
  }

  @override
  Widget build(BuildContext context) {
    // Zero-Error Policy: No const on Widgets that might be effectively constant but complex
    // Typography: w800 mandatory for headers.
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. LIGHT-REFRACTING BACKGROUND
          // Base
          Container(color: const Color(0xFFFDFCFE)),
          
          // Atmospheric Orbs (Animated feel via layout)
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE5CCFF).withOpacity(0.4), // Soft Violet
                boxShadow: [
                   BoxShadow(
                     color: Color(0xFF8B5CF6).withOpacity(0.2),
                     blurRadius: 100,
                   )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD6E7).withOpacity(0.4), // Soft Pink
                boxShadow: [
                   BoxShadow(
                     color: Color(0xFFEC4899).withOpacity(0.15),
                     blurRadius: 100,
                   )
                ],
              ),
            ),
          ),
          
          // Glass Blur Overlay (The Refraction)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
              child: Container(color: Colors.white.withOpacity(0.4)),
            ),
          ),

          // 2. CONTENT LAYER
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      
                      // 3. HERO ELEMENT: 3D-GLASS ORB logo
                      Container(
                        width: 140, // Large Hero Size
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9), // Milky Glass
                          border: Border.all(color: Colors.white, width: 2), // Ring
                          boxShadow: [
                            // 3D Shadow
                            BoxShadow(
                              color: Color(0xFF7C3AED).withOpacity(0.2), // Deep Violet Shadow
                              blurRadius: 30,
                              offset: Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 20,
                              offset: Offset(0, -5), // Top light source
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Image.asset(
                              'assets/images/savora_logo_clean.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // 4. TYPOGRAPHY
                      // "Savora" - w800, Pink-to-Purple Gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFEC4899), // Pink
                            Color(0xFF8B5CF6), // Purple
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          "Savora",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 42, // Mandate: 36pt (Increased for impact)
                            fontWeight: FontWeight.w800, // Mandate: w800
                            color: Colors.white, // Masked
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      Text(
                        "Your capital, guided by your intent.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                           fontSize: 16,
                           fontWeight: FontWeight.w500, // Mandate: w500
                           color: Color(0xFF1A1A1A).withOpacity(0.85), // Mandate: 0.85 opacity
                           letterSpacing: 0.2,
                           height: 1.5,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // 5. ACTION: 3D-TACTILE CAPSULE BUTTON
                      GestureDetector(
                        onTap: _completeWelcome,
                        child: Container(
                          width: double.infinity,
                          height: 64, // Large touch target
                          decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(32),
                             border: Border.all(
                               color: Color(0xFF8B5CF6).withOpacity(0.5), // Mandate: 0.5px Violet Glow
                               width: 1.0, 
                             ),
                             boxShadow: [
                               // High-Contrast Shadow
                               BoxShadow(
                                 color: Color(0xFF8B5CF6).withOpacity(0.3),
                                 blurRadius: 20,
                                 offset: Offset(0, 10),
                                 spreadRadius: -2,
                               ),
                             ],
                          ),
                          child: Center(
                            child: Text(
                              "Step Into Clarity",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800, // Mandate: w800 (Consistent)
                                color: Color(0xFF1A1A1A), // Dark text on white button
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
