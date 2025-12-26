import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/settings_service.dart';

class GlassOnboardingDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onDismiss;
  final Color accentColor;

  const GlassOnboardingDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onDismiss,
    this.accentColor = const Color(0xFF8B5CF6), // Default to Purple
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get Appearance Mode
    final isSharp = SettingsService().appearanceMode.value == AppearanceMode.sharp;
    final double radius = isSharp ? 4.0 : 32.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Global Blur Backdrop REMOVED (Caused sharp corners)

          // 2. The Gradient Border Container (Shadow Fixed)
          Container(
            constraints: BoxConstraints(maxWidth: 380),
            padding: EdgeInsets.all(1.5), // Subtle Border Width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEC4899), // Pink
                  Color(0xFF8B5CF6), // Purple
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.25),
                  blurRadius: 24, // Soft glow
                  spreadRadius: 2, 
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1.5), // Inner radius matches border padding
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(radius - 1.5),
                  ),
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon Container (White Glass)
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6), // Translucent backdrop
                              shape: isSharp ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: isSharp ? BorderRadius.circular(8) : null,
                              boxShadow: [
                                 BoxShadow(
                                   color: Colors.purple.withOpacity(0.05), // Tinted shadow
                                   blurRadius: 15,
                                   offset: Offset(0, 8),
                                 )
                              ],
                              border: Border.all(color: Colors.white, width: 2), // Crisp rim
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                              ).createShader(bounds),
                              child: Icon(icon, size: 36, color: Colors.white), 
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937), // Dark Grey
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          
                          SizedBox(height: 12),
                          
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4B5563), // Medium Grey
                              height: 1.5,
                            ),
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Action Button (Gradient Pill)
                          GestureDetector(
                            onTap: onDismiss,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isSharp ? 4 : 100),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFEC4899), // Pink
                                    Color(0xFF8B5CF6), // Purple
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFEC4899).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Start Exploring",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white, // White Text on Gradient
                                    letterSpacing: 0.5,
                                  ),
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
            ),
        ],
      ),
    );
  }
}
