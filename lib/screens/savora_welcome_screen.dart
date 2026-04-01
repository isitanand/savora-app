import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../data/settings_service.dart';
import '../main.dart'; 

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
    
    SettingsService().setHasSeenWelcome(true);
  }

  @override
  Widget build(BuildContext context) {
    
    
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          
          
          Container(color: const Color(0xFFFDFCFE)),
          
          
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE5CCFF).withOpacity(0.4), 
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
                color: Color(0xFFFFD6E7).withOpacity(0.4), 
                boxShadow: [
                   BoxShadow(
                     color: Color(0xFFEC4899).withOpacity(0.15),
                     blurRadius: 100,
                   )
                ],
              ),
            ),
          ),
          
          
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
              child: Container(color: Colors.white.withOpacity(0.4)),
            ),
          ),

          
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
                      
                      
                      Container(
                        width: 140, 
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9), 
                          border: Border.all(color: Colors.white, width: 2), 
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF7C3AED).withOpacity(0.2), 
                              blurRadius: 30,
                              offset: Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 20,
                              offset: Offset(0, -5), 
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

                      
                      
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFEC4899), 
                            Color(0xFF8B5CF6), 
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          "Savora",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 42, 
                            fontWeight: FontWeight.w800, 
                            color: Colors.white, 
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
                           fontWeight: FontWeight.w500, 
                           color: Color(0xFF1A1A1A).withOpacity(0.85), 
                           letterSpacing: 0.2,
                           height: 1.5,
                        ),
                      ),

                      const Spacer(flex: 3),

                      
                      GestureDetector(
                        onTap: _completeWelcome,
                        child: Container(
                          width: double.infinity,
                          height: 64, 
                          decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(32),
                             border: Border.all(
                               color: Color(0xFF8B5CF6).withOpacity(0.5), 
                               width: 1.0, 
                             ),
                             boxShadow: [
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
                                fontWeight: FontWeight.w800, 
                                color: Color(0xFF1A1A1A), 
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
