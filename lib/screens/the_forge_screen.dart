import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/core_drawer.dart';
import '../widgets/glass_onboarding_dialog.dart';
import '../data/settings_service.dart';
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';

class TheForgeScreen extends StatefulWidget {
  TheForgeScreen({super.key});

  @override
  State<TheForgeScreen> createState() => _TheForgeScreenState();
}

class _TheForgeScreenState extends State<TheForgeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  // Dynamic Metrics
  double _disciplineScore = 0.0;
  String _disciplineLabel = "Level 0: Novice";
  
  double _consistencyScore = 0.0;
  String _consistencyLabel = "Level 0: Starter";
  
  double _awarenessScore = 0.0;
  String _awarenessLabel = "Level 0: Observer";

  String _insightLowMetricLabel = "Awareness";
  String _insightAdvice = "Start logging reflections to awaken the forge.";
  Color _insightColor = Color(0xFF06B6D4);
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenForgeOnboarding.value) {
        _showOnboarding();
      }
      _loadMetrics();
    });
  }

  Future<void> _loadMetrics() async {
    final entries = await DataService().repository.getEntries();
    
    if (entries.isEmpty) {
      if (mounted) {
        setState(() {
          _disciplineScore = 0.0; _disciplineLabel = "Level 0: Empty";
          _consistencyScore = 0.0; _consistencyLabel = "Level 0: Void";
          _awarenessScore = 0.0; _awarenessLabel = "Level 0: Silent";
          _isLoading = false;
        });
      }
      return;
    }

    // 1. Discipline (Streak / Regularity)
    // Simple logic: % of unique days in the last 7 days that have an entry.
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    int daysWithEntries = 0;
    
    for (var day in last7Days) {
      bool hasEntry = entries.any((e) => 
        e.timestamp.year == day.year && 
        e.timestamp.month == day.month && 
        e.timestamp.day == day.day
      );
      if (hasEntry) daysWithEntries++;
    }
    
    double discScore = daysWithEntries / 7.0;
    String discLbl = _getLevelLabel(discScore);

    // 2. Consistency (Volume)
    // Simple logic: Total entries this month / 30 (cap at 1.0)
    final thisMonthEntries = entries.where((e) => e.timestamp.month == now.month && e.timestamp.year == now.year).length;
    double consScore = (thisMonthEntries / 30.0).clamp(0.0, 1.0);
    String consLbl = _getLevelLabel(consScore);

    // 3. Awareness (Depth)
    // Simple logic: Average Note Length + Context Diversity
    double avgLength = entries.fold(0, (sum, e) => sum + e.note.length) / entries.length;
    // Normalize length: 200 chars is "max" (1.0)
    double lengthScore = (avgLength / 200.0).clamp(0.0, 1.0);
    
    double awareScore = lengthScore; 
    String awareLbl = _getLevelLabel(awareScore);

    // Determine Actionable Insight (Lowest Score)
    String recLabel = "Awareness";
    String recAdvice = "Reflect deeply on your spending.";
    Color recColor = Color(0xFF06B6D4);

    if (discScore <= consScore && discScore <= awareScore) {
      recLabel = "Discipline";
      recAdvice = "Try to log at least one entry every day to build your streak.";
      recColor = Color(0xFF8B5CF6);
    } else if (consScore <= discScore && consScore <= awareScore) {
      recLabel = "Consistency";
      recAdvice = "Increase your logging frequency to capture more data points.";
      recColor = Color(0xFFD946EF);
    } else {
      recLabel = "Awareness";
      recAdvice = "Add detailed notes to your entries to deepen your insights.";
      recColor = Color(0xFF06B6D4);
    }

    if (mounted) {
      setState(() {
        _disciplineScore = discScore;
        _disciplineLabel = discLbl;
        _consistencyScore = consScore;
        _consistencyLabel = consLbl;
        _awarenessScore = awareScore;
        _awarenessLabel = awareLbl;
        
        _insightLowMetricLabel = recLabel;
        _insightAdvice = recAdvice;
        _insightColor = recColor;
        _isLoading = false;
      });
    }
  }

  String _getLevelLabel(double score) {
    if (score == 0) return "Level 0: Void";
    if (score < 0.3) return "Level 1: Spark";
    if (score < 0.6) return "Level 2: Flame";
    if (score < 0.8) return "Level 3: Blaze";
    return "Level 4: Inferno";
  }

  void _showOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlassOnboardingDialog(
        title: "The Three Pillars",
        description: "Discipline. Consistency. Awareness.\n\nForge these qualities by tracking consecutively and staying within your limits. Higher levels unlock deeper insights.",
        icon: Icons.diamond_rounded, 
        accentColor: Color(0xFFD946EF), 
        onDismiss: () {
          SettingsService().setHasSeenForgeOnboarding(true);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildPillarItem(String title, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 2),
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
              SizedBox(height: 4),
              Text(desc, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black54, height: 1.4)),
            ],
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showAchievementMatrix(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 40, offset: Offset(0, 20)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Color(0xFF8B5CF6), size: 28),
                    SizedBox(width: 12),
                    Text("Achievement Matrix", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  ],
                ),
                SizedBox(height: 24),
                _buildInfoRow("Discipline (Violet)", "Track daily to build your streak.", Color(0xFF8B5CF6)),
                SizedBox(height: 16),
                _buildInfoRow("Consistency (Pink)", "Log frequently to fill volume.", Color(0xFFD946EF)),
                SizedBox(height: 16),
                _buildInfoRow("Awareness (Cyan)", "Write detailed notes for depth.", Color(0xFF06B6D4)),
                SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Got it", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.grey)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 4),
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              SizedBox(height: 4),
              Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F3FF),
      drawer: CoreDrawer(),
      body: Stack(
        children: [
          // 1. LIGHT BASE (Standard)
          Container(color: Color(0xFFFDFCFE)),

          // 2. ATMOSPHERIC ORBS
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE3D5FF).withOpacity(0.5), // Lavender
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD6E7).withOpacity(0.5), // Pink
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCBF3F0).withOpacity(0.4), // Cyan
              ),
            ),
          ),

          // 3. GLOBAL ATMOSPHERIC BLUR
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
              child: Container(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              // 1. Standard Vanishing Header
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                pinned: false,
                centerTitle: true,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.menu_rounded, color: Color(0xFF1A1A1A), size: 20),
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: Text(
                  "The Forge",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.info_outline_rounded, color: Color(0xFF1A1A1A), size: 20),
                    ),
                    onPressed: () => _showAchievementMatrix(context),
                  ),
                  SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 2. The Artifact (Pulsing Crystal)
              SliverToBoxAdapter(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.1); // 1.0 -> 1.1
                      final glowOpacity = 0.3 + (_pulseController.value * 0.3); // 0.3 -> 0.6
                      
                      return Container(
                         width: 140, height: 140,
                         child: Stack(
                           alignment: Alignment.center,
                           children: [
                             // Pulse Ripple
                             Container(
                               width: 140 * scale,
                               height: 140 * scale,
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 gradient: RadialGradient(
                                   colors: [
                                     Color(0xFFD946EF).withOpacity(glowOpacity * 0.5), // Pink
                                     Colors.transparent,
                                   ],
                                 ),
                               ),
                             ),
                             
                             // The Crystal
                             ClipRRect(
                               borderRadius: BorderRadius.circular(24), 
                               child: BackdropFilter(
                                 filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                 child: Container(
                                   width: 90,
                                   height: 90,
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(24),
                                       color: Colors.white.withOpacity(0.4), // More glass
                                       border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                                       gradient: LinearGradient(
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                         colors: [
                                           Colors.white.withOpacity(0.9),
                                           Colors.white.withOpacity(0.2),
                                         ]
                                       ),
                                       boxShadow: [
                                         // Savora Glow (Pink/Purple Mix, very soft)
                                         BoxShadow(
                                           color: Color(0xFFD946EF).withOpacity(0.25),
                                           blurRadius: 50,
                                           spreadRadius: 0,
                                           offset: Offset(0, 8),
                                         ),
                                         BoxShadow(
                                           color: Colors.white.withOpacity(0.5),
                                           blurRadius: 20,
                                           spreadRadius: -5,
                                           offset: Offset(0, 0),
                                         )
                                       ]
                                     ),
                                   child: Center(
                                     child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         ),
                      );
                    },
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 32)),

              // 3. Progress Bars (Dynamic)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProgressRow("Discipline", _disciplineLabel, _disciplineScore, Color(0xFF8B5CF6)), // Violet
                    SizedBox(height: 24),
                    _buildProgressRow("Consistency", _consistencyLabel, _consistencyScore, Color(0xFFD946EF)), // Pink
                    SizedBox(height: 24),
                    _buildProgressRow("Awareness", _awarenessLabel, _awarenessScore, Color(0xFF06B6D4)), // Cyan
                    
                    SizedBox(height: 48),

                    // Actionable Insight
                    if (_isLoading)
                       Center(child: CircularProgressIndicator())
                    else
                       _buildActionableInsight(_insightLowMetricLabel, _insightAdvice, _insightColor),
                  ]),
                ),
              ),

               SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String level, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A).withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              level,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600, 
                color: Color(0xFF1A1A1A).withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ValueListenableBuilder<AppearanceMode>(
          valueListenable: SettingsService().appearanceMode,
          builder: (context, mode, _) {
            final isSharp = mode == AppearanceMode.sharp;
            final double radius = isSharp ? 0.0 : 100.0;
            
            return Container(
              height: 16, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutExpo,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                           gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                           borderRadius: BorderRadius.circular(radius),
                           boxShadow: [
                             BoxShadow(color: color.withOpacity(0.5), blurRadius: 12, offset: Offset(0, 0), spreadRadius: 1),
                           ]
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }
        ),
      ],
    );
  }

  Widget _buildActionableInsight(String category, String advice, Color color) {
    // Override with App Theme Gradient (Pink -> Violet) for consistency
    final Color c1 = Color(0xFFD946EF); // Pink
    final Color c2 = Color(0xFF8B5CF6); // Violet

    return ValueListenableBuilder<AppearanceMode>(
      valueListenable: SettingsService().appearanceMode,
      builder: (context, mode, _) {
        final isSharp = mode == AppearanceMode.sharp;
        final double radius = isSharp ? 0.0 : 24.0;
        final double iconRadius = isSharp ? 0.0 : 50.0;

        return GestureDetector(
          onTap: () {
            // Navigate to Home to take action
            Navigator.of(context).pushReplacementNamed('/');
          },
          child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65), // Thick Glass
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white, 
              width: 2.0
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD946EF).withOpacity(0.15), // Soft Pink Glow
                blurRadius: 40,
                offset: Offset(0, 15),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(iconRadius), 
                        boxShadow: [
                           BoxShadow(color: c1.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8)),
                        ],
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.white.withOpacity(0.9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [c1, c2],
                        ).createShader(bounds),
                        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    SizedBox(width: 20),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "RECOMMENDED ACTION: ${category.toUpperCase()}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: c1, 
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            advice,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: c2.withOpacity(0.4)),
                  ],
                ),
              ),
            ),
          ),
          ),
        ); 
      }
    );
  }
}
