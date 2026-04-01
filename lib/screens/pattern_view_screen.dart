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
    
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenAnalyticsOnboarding.value) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GlassOnboardingDialog(
            title: "Pattern Recognition",
            description: "Decode your behavior.\n\nExplore Mood Heatmaps, Location Analysis, and Time-Velocity patterns to understand the 'Why' behind every transaction.",
            icon: Icons.pie_chart_rounded, 
            accentColor: Color(0xFF3B82F6), 
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
      
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : Stack(
              children: [
                
                Container(color: Color(0xFFFDFCFE)),

                
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

                
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

                
                CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    
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
                        "Analytics",
                        style: GoogleFonts.plusJakartaSans(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 20)),

                    
                    SliverPadding(
                      padding: EdgeInsets.only(left: 20, top: 20, right: 20),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "Financial Overview",
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

                    SliverToBoxAdapter(child: SizedBox(height: 24)),

                    
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                         child: _buildFinancialOverviewCards(),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 40)),
                    
                    
                    SliverPadding(
                      padding: EdgeInsets.only(left: 24, right: 24, bottom: 16),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "Behavioral Insights",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A).withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 32)),

                    
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          padding: EdgeInsets.all(24),
                          title: "Mood Correlation",
                          subtitle: "Which emotions trigger spending?",
                          child: _MoodHeatmap(entries: _entries),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 24)),

                    
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          padding: EdgeInsets.all(24),
                          title: "Places Analysis",
                          subtitle: "Where do you spend the most?",
                          child: _ContextHeatmap(entries: _entries),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 24)),

                    
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          padding: EdgeInsets.all(32), 
                          title: "Time-Velocity Matrix",
                          subtitle: "Hourly spending intensity (Last 24h)",
                          child: SizedBox(
                            height: 320, 
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

  Widget _buildFinancialOverviewCards() {
    final now = DateTime.now();
    
    final monthlyExpenses = _entries
        .where((e) => e.amount < 0 && e.context != 'Favor' && e.timestamp.year == now.year && e.timestamp.month == now.month)
        .fold<double>(0, (sum, e) => sum + e.amount.abs());

    
    final Map<String, double> contextTotals = {};
    for (var e in _entries) {
      if (e.amount < 0 && e.context != 'Favor') {
        final ctx = e.context.isEmpty ? 'Unknown' : e.context;
        contextTotals[ctx] = (contextTotals[ctx] ?? 0) + e.amount.abs();
      }
    }
    String topCategory = "None";
    double topCategoryValue = 0;
    if (contextTotals.isNotEmpty) {
      final sorted = contextTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key;
      topCategoryValue = sorted.first.value;
    }

    
    final thisWeekSpend = _entries
        .where((e) => e.amount < 0 && e.context != 'Favor' && e.timestamp.isAfter(now.subtract(Duration(days: 7))))
        .fold<double>(0, (sum, e) => sum + e.amount.abs());
    
    final lastWeekSpend = _entries
        .where((e) => e.amount < 0 && e.context != 'Favor' && 
                 e.timestamp.isAfter(now.subtract(Duration(days: 14))) && e.timestamp.isBefore(now.subtract(Duration(days: 7))))
        .fold<double>(0, (sum, e) => sum + e.amount.abs());
        
    double weeklyChange = 0;
    if (lastWeekSpend > 0) {
      weeklyChange = ((thisWeekSpend - lastWeekSpend) / lastWeekSpend) * 100;
    } else if (thisWeekSpend > 0) {
      weeklyChange = 100; 
    }
    bool isIncrease = weeklyChange > 0;
    String weeklyText = "";
    if (lastWeekSpend == 0 && thisWeekSpend == 0) {
        weeklyText = "No data";
    } else {
        weeklyText = "${weeklyChange.abs().toStringAsFixed(1)}% ${isIncrease ? 'up' : 'down'} vs last wk";
    }

    return Column(
      children: [
        Row(
           children: [
             Expanded(
               child: _OverviewMiniCard(
                 title: "Monthly Total",
                 value: "₹${monthlyExpenses.toStringAsFixed(0)}",
                 subtitle: "This month",
                 icon: Icons.account_balance_wallet_rounded,
                 color: Color(0xFF8B5CF6),
               ),
             ),
             SizedBox(width: 12),
             Expanded(
               child: _OverviewMiniCard(
                 title: "Top Category",
                 value: topCategory,
                 subtitle: "₹${topCategoryValue.toStringAsFixed(0)}",
                 icon: Icons.category_rounded,
                 color: Color(0xFFEC4899),
               ),
             ),
           ],
        ),
        SizedBox(height: 12),
        _OverviewMiniCard(
          title: "Weekly Comparison",
          value: "₹${thisWeekSpend.toStringAsFixed(0)}",
          subtitle: weeklyText,
          icon: isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: isIncrease ? Colors.redAccent : Colors.green,
          isFullWidth: true,
        ),
      ],
    );
  }
}


class _GlassCard extends StatelessWidget {
  final double? height; 
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
              height: height, 
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
               
              Positioned.fill(
                child: CustomPaint(
                  painter: _GradientBorderPainter(mode),
                ),
              ),
              
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisSize: MainAxisSize.min, 
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
                    child, 
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
              
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280), 
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              
              Expanded(
                child: Stack(
                  children: [
                    
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                    
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
                                Color(0xFFC026D3), 
                                Color(0xFF8B5CF6), 
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
                                Color(0xFFC026D3), 
                                Color(0xFF8B5CF6), 
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
    
    final maxRadius = min(w, h) / 2 - 30; 
    
    
    final gridPaint = Paint()
      ..color = Color(0xFF1A1A1A).withOpacity(0.1) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    
    canvas.drawCircle(center, maxRadius * 0.33, gridPaint);
    canvas.drawCircle(center, maxRadius * 0.66, gridPaint);
    canvas.drawCircle(center, maxRadius, gridPaint);

    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), gridPaint);
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), gridPaint);
    
    
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A1A).withOpacity(0.4), 
    );
    
    _drawLabel(canvas, "12 AM",   Offset(center.dx, center.dy - maxRadius - 24), textStyle);
    _drawLabel(canvas, "6 AM",    Offset(center.dx + maxRadius + 24, center.dy), textStyle);
    _drawLabel(canvas, "12 PM",   Offset(center.dx, center.dy + maxRadius + 24), textStyle);
    _drawLabel(canvas, "6 PM",    Offset(center.dx - maxRadius - 24, center.dy), textStyle);

    
    if (entries.isEmpty) return;

    final maxVal = entries.map((e) => e.amount.abs()).reduce(max);
    final safeMax = maxVal == 0 ? 100.0 : maxVal;

    for (var e in entries) {
      final t = e.timestamp;
      
      double hour = t.hour + (t.minute / 60.0);
      double angle = (hour / 24.0) * 2 * pi - (pi / 2); 
      
      final amt = e.amount.abs();
      
      final r = (0.2 + 0.8 * (amt / safeMax)) * maxRadius;
      
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;

      
      final bubbleSize = 8.0 + (amt / safeMax) * 12.0;

      final orbCenter = Offset(x, y);

      
      canvas.drawCircle(
        orbCenter.translate(0, 4), 
        bubbleSize, 
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );

      
      
      final gradient = ui.Gradient.radial(
        orbCenter.translate(-bubbleSize * 0.3, -bubbleSize * 0.3), 
        bubbleSize * 1.5,
        [
          Color(0xFFE9D5FF), 
          Color(0xFF7C3AED), 
        ],
      );
      
      canvas.drawCircle(
        orbCenter,
        bubbleSize,
        Paint()..shader = gradient,
      );

      
      canvas.drawCircle(
        orbCenter.translate(-bubbleSize * 0.3, -bubbleSize * 0.3),
        bubbleSize * 0.25,
        Paint()..color = Colors.white.withOpacity(0.9), 
      );
      
      
      
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
          Color(0xFFD946EF).withOpacity(0.6), 
          Color(0xFF8B5CF6).withOpacity(0.6), 
        ],
      );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OverviewMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isFullWidth;

  const _OverviewMiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isFullWidth 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Container(
                     padding: EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: color.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(icon, color: color, size: 20),
                   ),
                   SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: CoreTheme.deepInk.withOpacity(0.7), fontWeight: FontWeight.w600)),
                       Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, color: CoreTheme.deepInk, fontWeight: FontWeight.w800)),
                     ],
                   ),
                ]
              ),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Container(
                     padding: EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: color.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(icon, color: color, size: 18),
                   ),
                 ],
               ),
               SizedBox(height: 12),
               Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: CoreTheme.deepInk.withOpacity(0.7), fontWeight: FontWeight.w600)),
               SizedBox(height: 4),
               Text(
                 value, 
                 style: GoogleFonts.plusJakartaSans(fontSize: 16, color: CoreTheme.deepInk, fontWeight: FontWeight.w800),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
               SizedBox(height: 2),
               Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: CoreTheme.deepInk.withOpacity(0.5))),
            ],
        ),
    );
  }
}
