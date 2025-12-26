import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';
import '../theme/core_theme.dart';
import '../widgets/glass_onboarding_dialog.dart';
import '../widgets/core_drawer.dart';
import '../data/settings_service.dart';

class PatternViewScreen extends StatefulWidget {
  const PatternViewScreen({super.key});

  @override
  State<PatternViewScreen> createState() => _PatternViewScreenState();
}

class _PatternViewScreenState extends State<PatternViewScreen> {
  List<ReflectionEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Check Onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenAnalyticsOnboarding.value) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GlassOnboardingDialog(
            title: "Pattern Recognition",
            description: "Decode your behavior.\n\nExplore Mood Heatmaps, Location Analysis, and Time-Velocity patterns to understand the 'Why' behind every transaction.",
            icon: Icons.pie_chart_rounded, // or insights_rounded
            accentColor: Color(0xFF3B82F6), // Blue
            onDismiss: () {
              Navigator.pop(context);
              SettingsService().setHasSeenAnalyticsOnboarding(true);
            },
          ),
        );
      }
    });
  }

  Future<void> _loadData() async {
    final entries = await DataService().repository.getEntries();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F3FF),
      drawer: CoreDrawer(),
      // Mandate: Vanishing Header -> No fixed AppBar
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : Stack(
              children: [
                // 1. LIGHT BASE
                Container(color: Color(0xFFFDFCFE)),

                // 2. ATMOSPHERIC ORBS (Lavender, Pink, Cyan)
                Positioned(
                  top: -100,
                  left: -50,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE3D5FF).withOpacity(0.5),
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
                      color: Color(0xFFFFD6E7).withOpacity(0.5),
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
                      color: Color(0xFFCBF3F0).withOpacity(0.4),
                    ),
                  ),
                ),

                // 3. GLOBAL ATMOSPHERIC BLUR
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

                // Content
                CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    // 1. Vanishing Header (SliverAppBar)
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      floating: true, // Mandate: Vanish on scroll
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
                        "Analytics",
                        style: GoogleFonts.plusJakartaSans(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 2. Big Title
                    SliverPadding(
                      padding: EdgeInsets.only(left: 20, top: 20, right: 20),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "Deep Behavioral\nMapping",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -1.0,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // 3. MOOD HEATMAP
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          // height: null, // Dynamic height
                          padding: EdgeInsets.all(24),
                          title: "Mood Correlation",
                          subtitle: "Which emotions trigger spending?",
                          child: _MoodHeatmap(entries: _entries),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // 4. PLACES ANALYSIS
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          // height: null, // Dynamic height
                          padding: EdgeInsets.all(24),
                          title: "Places Analysis",
                          subtitle: "Where do you spend the most?",
                          child: _ContextHeatmap(entries: _entries),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // 5. VELOCITY MATRIX (Radar)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          // height: null, // Let child define height
                          padding: EdgeInsets.all(32), 
                          title: "Time-Velocity Matrix",
                          subtitle: "Hourly spending intensity (Last 24h)",
                          child: SizedBox(
                            height: 320, // Fixed height for Chart
                            child: _VelocityScatter(
                              entries: _entries.where((e) => 
                                e.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 24)))
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                ),
              ],
            ),
    );
  }
}

// --- GLASS COMPONENT ---
class _GlassCard extends StatelessWidget {
  final double? height; // Nullable for dynamic height
  final String title;
  final String subtitle;
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    this.height,
    required this.title,
    required this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppearanceMode>(
      valueListenable: SettingsService().appearanceMode,
      builder: (context, mode, _) {
        final isSharp = mode == AppearanceMode.sharp;
        final double radius = isSharp ? 0.0 : 24.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: height, // Can be null
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7C3AED).withOpacity(0.05),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            child: Stack(
            children: [
               // Gradient Border (Outer Ring)
              Positioned.fill(
                child: CustomPaint(
                  painter: _GradientBorderPainter(mode),
                ),
              ),
              
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Left align title
                  mainAxisSize: MainAxisSize.min, // Wrap content
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800, 
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A).withOpacity(0.5),
                      ),
                    ),
                    SizedBox(height: 24),
                    child, // No Expanded, just child
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
      }
    );
  }
}

// --- CHARTS ---

class _MoodHeatmap extends StatelessWidget {
  final List<ReflectionEntry> entries;

  const _MoodHeatmap({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No data yet")));

    final Map<String, double> moodTotals = {};
    for (var e in entries) {
      if (e.mood.isNotEmpty) {
        String m = e.mood; 
        moodTotals[m] = (moodTotals[m] ?? 0) + e.amount.abs();
      }
    }

    final sorted = moodTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMoods = sorted.take(4).toList(); 
    if (topMoods.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No mood data yet")));

    final maxSpend = topMoods.first.value;

    Widget _buildBar(String label, Color color, double amount, double max) {
    if (amount <= 0) return SizedBox.shrink();
    
    final widthFactor = amount / max;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: ValueListenableBuilder<AppearanceMode>(
        valueListenable: SettingsService().appearanceMode,
        builder: (context, mode, _) {
          final isSharp = mode == AppearanceMode.sharp;
          final double radius = isSharp ? 0.0 : 6.0;

          return Row(
            children: [
              // Label (Left)
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280), // Grey 500
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Bar
              Expanded(
                child: Stack(
                  children: [
                    // Bg
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: Container(
                         height: 12,
                         decoration: BoxDecoration(
                           gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
                           borderRadius: BorderRadius.circular(radius),
                           boxShadow: [
                             BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2)),
                           ],
                         ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 16),
              
              // Amount (Right)
              SizedBox(
                width: 50,
                child: Text(
                  "₹${amount.toStringAsFixed(0)}",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
    return Column(
      children: topMoods.map((e) {
        final percentage = e.value / maxSpend;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0), 
          child: Row(
            children: [
              SizedBox(
                width: 70, 
                child: Text(
                  e.key,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A).withOpacity(0.5), 
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 12),
              
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFF3E8FF), 
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: FractionallySizedBox(
                        widthFactor: percentage.clamp(0.02, 1.0),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFC026D3), // Pink
                                Color(0xFF8B5CF6), // Purple
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              
              SizedBox(
                width: 50,
                child: Text(
                  "₹${e.value.toStringAsFixed(0)}",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1A1A1A).withOpacity(0.5), 
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ContextHeatmap extends StatelessWidget {
  final List<ReflectionEntry> entries;

  const _ContextHeatmap({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No data yet")));

    final Map<String, double> contextTotals = {};
    for (var e in entries) {
      String ctx = e.context.isEmpty ? "Unknown" : e.context; 
      contextTotals[ctx] = (contextTotals[ctx] ?? 0) + e.amount.abs();
    }

    final sorted = contextTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topContexts = sorted.take(4).toList(); 
    if (topContexts.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No places data yet")));

    final maxSpend = topContexts.first.value;

    return Column(
      children: topContexts.map((e) {
        final percentage = e.value / maxSpend;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0), 
          child: Row(
            children: [
              SizedBox(
                width: 70, 
                child: Text(
                  e.key,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A).withOpacity(0.5), 
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 12),
              
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFF3E8FF), 
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: FractionallySizedBox(
                        widthFactor: percentage.clamp(0.02, 1.0),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFC026D3), // Pink
                                Color(0xFF8B5CF6), // Purple
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              
              SizedBox(
                width: 50,
                child: Text(
                  "₹${e.value.toStringAsFixed(0)}",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1A1A1A).withOpacity(0.5), 
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _VelocityScatter extends StatelessWidget {
  final List<ReflectionEntry> entries;

  const _VelocityScatter({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return Center(child: Text("No data in 24h"));

    return CustomPaint(
      size: Size.infinite,
      painter: _ScatterPainter(entries),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<ReflectionEntry> entries;

  _ScatterPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    // Increase margin to prevent label overlap
    final maxRadius = min(w, h) / 2 - 30; 
    
    // Grid: Faint concentric rings (10% opacity)
    final gridPaint = Paint()
      ..color = Color(0xFF1A1A1A).withOpacity(0.1) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 1. Radar Grid
    canvas.drawCircle(center, maxRadius * 0.33, gridPaint);
    canvas.drawCircle(center, maxRadius * 0.66, gridPaint);
    canvas.drawCircle(center, maxRadius, gridPaint);

    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), gridPaint);
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), gridPaint);
    
    // 2. Labels (Moved further out)
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A1A).withOpacity(0.4), 
    );
    
    _drawLabel(canvas, "12 AM",   Offset(center.dx, center.dy - maxRadius - 24), textStyle);
    _drawLabel(canvas, "6 AM",    Offset(center.dx + maxRadius + 24, center.dy), textStyle);
    _drawLabel(canvas, "12 PM",   Offset(center.dx, center.dy + maxRadius + 24), textStyle);
    _drawLabel(canvas, "6 PM",    Offset(center.dx - maxRadius - 24, center.dy), textStyle);

    // 3. Data Points (Glass Orbs)
    if (entries.isEmpty) return;

    final maxVal = entries.map((e) => e.amount.abs()).reduce(max);
    final safeMax = maxVal == 0 ? 100.0 : maxVal;

    for (var e in entries) {
      final t = e.timestamp;
      
      double hour = t.hour + (t.minute / 60.0);
      double angle = (hour / 24.0) * 2 * pi - (pi / 2); 
      
      final amt = e.amount.abs();
      // Radius distribution: 20% min + scaled remainder
      final r = (0.2 + 0.8 * (amt / safeMax)) * maxRadius;
      
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;

      // Bubble Size: slightly larger for 3D effect impact
      final bubbleSize = 8.0 + (amt / safeMax) * 12.0;

      final orbCenter = Offset(x, y);

      // A. Sharp Drop Shadow (Depth)
      canvas.drawCircle(
        orbCenter.translate(0, 4), // Offset down
        bubbleSize, 
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );

      // B. Orb Gradient Fill (Radial)
      // Light Lilac center -> Deep Violet edge
      final gradient = ui.Gradient.radial(
        orbCenter.translate(-bubbleSize * 0.3, -bubbleSize * 0.3), // Light source top-left
        bubbleSize * 1.5,
        [
          Color(0xFFE9D5FF), // Light Lilac
          Color(0xFF7C3AED), // Deep Violet
        ],
      );
      
      canvas.drawCircle(
        orbCenter,
        bubbleSize,
        Paint()..shader = gradient,
      );

      // C. High Gloss Reflection (The "Wet" look)
      canvas.drawCircle(
        orbCenter.translate(-bubbleSize * 0.3, -bubbleSize * 0.3),
        bubbleSize * 0.25,
        Paint()..color = Colors.white.withOpacity(0.9), // Crisp white
      );
      
      // D. Subtle Rim Light (Bottom Right)
      // canvas.drawArc(...) // Optional, maybe overkill for now. Gloss is key.
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, TextStyle style) {
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GradientBorderPainter extends CustomPainter {
  final AppearanceMode mode;
  _GradientBorderPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final isSharp = mode == AppearanceMode.sharp;
    final double radius = isSharp ? 0.0 : 24.0;

    // Mandate: 0.8px Vibrant Pink-to-Purple gradient sweep border
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), 
      Radius.circular(radius)
    );
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          Color(0xFFD946EF).withOpacity(0.6), // Pink (Slightly reduced for elegance)
          Color(0xFF8B5CF6).withOpacity(0.6), // Purple
        ],
      );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
