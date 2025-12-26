import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/daily_stream_screen.dart';
import '../widgets/glass_onboarding_dialog.dart';
import '../data/settings_service.dart';

class QuietSpaceScreen extends StatefulWidget {
  // Mandate: No const
  QuietSpaceScreen({super.key});

  @override
  State<QuietSpaceScreen> createState() => _QuietSpaceScreenState();
}

class _QuietSpaceScreenState extends State<QuietSpaceScreen> with SingleTickerProviderStateMixin {
  bool _breatheIn = true;
  int _breathCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 4s In, 4s Out = 8s cycle
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _breatheIn = !_breatheIn;
          if (_breatheIn) {
            _breathCount++; // Increment on start of new inhale (cycle start)
          }
        });
      }
    });

    // Check Onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenQuietSpaceOnboarding.value) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GlassOnboardingDialog(
            title: "Quiet Space",
            description: "Pause the impulse.\n\nBreathe in your intent, breathe out the urge. Find clarity before you commit.",
            icon: Icons.spa_rounded,
            accentColor: Color(0xFFD946EF), // Pink/Magenta
            onDismiss: () {
              Navigator.pop(context);
              SettingsService().setHasSeenQuietSpaceOnboarding(true);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(Icons.close_rounded, color: Color(0xFF1A1A1A), size: 20),
          ),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => DailyStreamScreen()),
            (route) => false,
          ),
        ),
        title: Text(
          "Quiet Space",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. CREAMY BASE
          Container(color: Color(0xFFF9FAFB)), // Very light grey base

          // 2. DREAMY ORBS (Pastels)
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE9D5FF).withOpacity(0.6), // Soft Lilac
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE4E6).withOpacity(0.6), // Rose
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCCFBF1).withOpacity(0.5), // Soft Teal
              ),
            ),
          ),

          // 3. SUPER ATMOSPHERIC BLUR (Creamy Effect)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
              child: Container(
                color: Colors.white.withOpacity(0.3), // Milky overlay
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 4. THE FROSTED PEARL
                AnimatedContainer(
                  duration: Duration(seconds: 4),
                  curve: Curves.easeInOutCubic, // Smoother breathing
                  width: _breatheIn ? 280 : 220, 
                  height: _breatheIn ? 280 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Pearl Gradient: Soft Violet to Pink (More contrast than white)
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFF3E8FF), // Light Violet (Center highlight)
                        Color(0xFFF0ABFC), // Soft Pink/Fuchsia (Edge)
                      ],
                      stops: [0.2, 1.0],
                      center: Alignment(-0.3, -0.3), // Highlight offset
                    ),
                    boxShadow: [
                      // Deep Soft Shadow for 3D Pop
                      BoxShadow(
                        color: Color(0xFFC026D3).withOpacity(_breatheIn ? 0.3 : 0.15), // Deep Purple/Pink Shadow
                        blurRadius: _breatheIn ? 60 : 30, // Dynamic depth
                        spreadRadius: 5,
                        offset: Offset(0, 15),
                      ),
                      // Inner Rim Highlight (Simulated via White Glow)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 15,
                        offset: Offset(-8, -8), // Top-left rim light
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Reduced internal frost for clarity
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15), // Slight gloss
                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5), // Crisp Rim
                            ),
                          ),
                          // Crisp Reflection Highlight
                          Positioned(
                             top: 50,
                             left: 60,
                             child: Container(
                               width: 50,
                               height: 25,
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.5),
                                 borderRadius: BorderRadius.all(Radius.elliptical(50, 25)),
                                 boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 10)],
                               ),
                             ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 80),

                // 5. Elegant Text Prompt
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    _breatheIn ? "Breathe in Intent" : "Breathe out Impulse",
                    key: ValueKey(_breatheIn),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, // Larger
                      fontWeight: FontWeight.w300, // Light/Elegant
                      color: Color(0xFF374151), // Dark Grey
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                SizedBox(height: 16),
                
                // Static Subtext
                Text(
                  "Finding your center",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF), // Muted Grey
                    letterSpacing: 4.0, 
                  ),
                ),
              ],
            ),
          ),

          // 6. "I am centered" Button (Minimalist Glass)
          if (_breathCount >= 3)
            Positioned(
              bottom: 60,
              left: 0, 
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000),
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: val,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - val)),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => DailyStreamScreen()),
                      (route) => false,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Color(0xFFE9D5FF).withOpacity(0.3), blurRadius: 30, offset: Offset(0, 10))
                        ],
                      ),
                      child: Text(
                        "I am centered",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563), // Muted Text
                          letterSpacing: 1.0,
                        ),
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
