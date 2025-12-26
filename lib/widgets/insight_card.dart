import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/insight_model.dart';
import '../theme/core_theme.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Improved Spacing: Removed bottom margin to let parent handle layout
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.0), // Fully transparent base
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.25), // Reduced opacity border
          width: 0.8, 
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Softer blur
          child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
                 colors: [
                   Colors.white.withOpacity(0.35),
                   Colors.white.withOpacity(0.10),
                 ],
               ),
             ),
            child: Row(
              children: [
                // Integrated Icon (No container, just pure icon with gradient)
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_getGlowColor(insight.type), _getGlowColor(insight.type).withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Icon(
                    _getIcon(insight.type),
                    size: 20,
                    color: Colors.white, // Mask handles color
                  ),
                ),
                SizedBox(width: 16),
                
                // Typography - Natural & Integrated
                Expanded(
                  child: Text(
                    insight.message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, // Slightly smaller for "native" feel
                      fontWeight: FontWeight.w500, // Reduced weight from 600
                      height: 1.4,
                      color: Color(0xFF1A1A1A).withOpacity(0.75), // Softer textual contrast
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(InsightType type) {
    switch (type) {
      case InsightType.pattern: return Icons.timeline_rounded;
      case InsightType.change: return Icons.compare_arrows_rounded;
      case InsightType.emotional: return Icons.psychology_rounded; 
      case InsightType.velocity: return Icons.speed_rounded;
      case InsightType.reflection: return Icons.auto_awesome_rounded;
    }
  }

  Color _getGlowColor(InsightType type) {
    switch (type) {
      case InsightType.pattern: return Color(0xFF8B5CF6); 
      case InsightType.change: return Colors.blueAccent;
      case InsightType.emotional: return Color(0xFFEC4899); 
      case InsightType.velocity: return Colors.orangeAccent;
      case InsightType.reflection: return Color(0xFF1A1A1A); 
    }
  }
}
