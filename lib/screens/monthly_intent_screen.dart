import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../data/data_service.dart';
import '../data/models/monthly_intent.dart';
import '../data/settings_service.dart';
import '../theme/core_theme.dart';
import '../widgets/core_drawer.dart';
import '../widgets/glass_onboarding_dialog.dart';

class MonthlyIntentScreen extends StatefulWidget {
  const MonthlyIntentScreen({super.key});

  @override
  State<MonthlyIntentScreen> createState() => _MonthlyIntentScreenState();
}

class _MonthlyIntentScreenState extends State<MonthlyIntentScreen> with TickerProviderStateMixin {
  // 0 = Daily, 1 = Monthly
  int _selectedMode = 0; 
  String? _currentIntent;
  bool _isLoading = true;
  bool _isRedAlert = false; 

  // Pulse Gate Controllers
  late AnimationController _pulseController; 
  late AnimationController _holdController;  
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    // 1. Ripple Animation (Continuous)
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();

    // 2. Hold Animation (User controlled)
    _holdController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2), 
    );

    _fillAnimation = CurvedAnimation(parent: _holdController, curve: Curves.easeInOut);

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onFocusComplete();
      }
    });

    _loadData();
    
    // 4. Check Onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  void _checkOnboarding() {
    if (!SettingsService().hasSeenIntentOnboarding.value) {
      _showOnboardingDialog();
    }
  }

  Future<void> _showOnboardingDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlassOnboardingDialog(
        title: "Monthly Intent",
        description: "Set a clear financial limit for the month. This isn't just a budget—it's your commitment to conscious spending.",
        icon: Icons.track_changes_rounded,
        accentColor: Color(0xFF7C3AED),
        onDismiss: () {
            Navigator.pop(context);
            SettingsService().setHasSeenIntentOnboarding(true); 
        },
      ),
    );
    SettingsService().setHasSeenIntentOnboarding(true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    
    // Key Generation Logic
    String key;
    if (_selectedMode == 0) {
       // Daily Key: YYYY-MM-DD
       key = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    } else {
       // Monthly Key: YYYY-MM
       key = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    }
    
    final intent = await DataService().repository.getIntent(key);
    String? intentText = intent?.intentText;
    
    // LOGIC & RED ALERT
    final entries = await DataService().repository.getEntries();
    bool redAlert = false;

    if (_selectedMode == 0) {
      // --- DAILY MODE ---
      // Filter: Today, Midnight to Midnight
      final todayEntries = entries.where((e) => 
        e.timestamp.year == now.year && 
        e.timestamp.month == now.month && 
        e.timestamp.day == now.day
      ).toList();
      
      double spentToday = todayEntries.fold(0.0, (sum, e) => sum + e.amount.abs());
      double dailyLimit = SettingsService().dailyLimit.value;
      
      redAlert = dailyLimit > 0 && spentToday > dailyLimit;
    } else {
      // --- MONTHLY MODE ---
      final monthEntries = entries.where((e) => 
        e.timestamp.year == now.year && 
        e.timestamp.month == now.month
      ).toList();
      
      double spentMonth = monthEntries.fold(0.0, (sum, e) => sum + e.amount.abs());
      double monthlyLimit = SettingsService().monthlyLimit.value;
      
      redAlert = monthlyLimit > 0 && spentMonth > monthlyLimit;
    }

    if (mounted) {
      setState(() {
        _currentIntent = intentText;
        _isRedAlert = redAlert;
        _isLoading = false;
      });
    }
  }
  
  void _toggleMode(int mode) {
    if (_selectedMode != mode) {
      setState(() {
        _selectedMode = mode;
        _isLoading = true;
      });
      _loadData();
    }
  }

  // Interaction Logic
  void _startHold() {
    _holdController.forward();
  }

  void _endHold() {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reverse();
    }
  }

  void _onFocusComplete() async {
    await _showIntentDialog();
    _holdController.reset();
  }

  Future<void> _showIntentDialog() async {
    final controller = TextEditingController(text: _currentIntent);
    final isDaily = _selectedMode == 0;
    final hint = isDaily 
        ? "e.g., I don't want to exceed ₹100 today" 
        : "e.g., I don't want to exceed ₹4000 this month";
        
    final result = await showGeneralDialog<String>(
      context: context,
      barrierLabel: "Dismiss",
      barrierDismissible: true,
      pageBuilder: (context, anim1, anim2) => Container(), 
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(isDaily ? 'Daily Intent' : 'Monthly Intent', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              content: TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600), // Mandate: w600
                decoration: InputDecoration(
                  hintText: hint,
                  hintMaxLines: 2,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black26),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text.trim()),
                  child: Text('Commit', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      // 1. EXTRACT LIMIT LOGIC
      final numberRegExp = RegExp(r'(\d+)');
      final match = numberRegExp.firstMatch(result);
      if (match != null) {
        final amount = double.tryParse(match.group(0)!);
        if (amount != null && amount > 0) {
          if (isDaily) {
             SettingsService().setDailyLimit(amount);
          } else {
             SettingsService().setMonthlyLimit(amount);
          }
        }
      }

    // 2. GENERATE KEY BASED ON MODE
      final now = DateTime.now();
      String key;
      if (isDaily) {
        key = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      } else {
        key = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      }

      final newIntent = MonthlyIntent(
        id: const Uuid().v4(),
        monthYear: key,
        intentText: result,
        createdAt: DateTime.now(),
      );
      
      await DataService().repository.saveIntent(newIntent);
      
      setState(() {
        _currentIntent = result;
        _loadData(); 
      });
    }
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
                // 1. Atmosphere
                Positioned(
                  top: -100,
                  left: -50,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRedAlert 
                           ? Color(0xFFEF4444).withOpacity(0.2) // Stronger Red
                           : Color(0xFFC026D3).withOpacity(0.15),
                      ),
                    ),
                  ),
                ),

                CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    // 2. Vanishing Header
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      expandedHeight: 0, 
                      floating: true,
                      snap: true, // Ensured snap
                      pinned: false,
                      centerTitle: true,
                      leading: Builder(
                        builder: (context) => IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                               color: _isRedAlert 
                                 ? Color(0xFFEF4444).withOpacity(0.1) // Red Alert tint
                                 : Colors.white.withOpacity(0.5),
                               shape: BoxShape.circle,
                               border: _isRedAlert ? Border.all(color: Color(0xFFEF4444), width: 1.5) : null,
                            ),
                            child: Icon(Icons.menu_rounded, color: _isRedAlert ? Color(0xFFEF4444) : Color(0xFF1A1A1A), size: 20)
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      title: Text(
                        _selectedMode == 0 ? "Daily Intent" : "Monthly Intent",
                         style: GoogleFonts.plusJakartaSans(
                            fontSize: 20, // Reduced from 24
                            fontWeight: FontWeight.w800, 
                            color: Color(0xFF1A1A1A),
                         ),
                      ),
                    ),

                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          SizedBox(height: 24),
                          
                          // 3. 3D-Glass Segmented Control
                          _GlassSegmentedControl(
                            selectedIndex: _selectedMode,
                            onChanged: _toggleMode,
                            isRedAlert: _isRedAlert,
                          ),
                          
                          Spacer(),
                          
                          // 4. THE PULSE GATE
                          GestureDetector(
                            onTapDown: (_) => _startHold(),
                            onTapUp: (_) => _endHold(),
                            onTapCancel: () => _endHold(),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // A. Ripples
                                CustomPaint(
                                  size: Size(300, 300),
                                  painter: _RipplePainter(_pulseController, 
                                    color: _isRedAlert ? Color(0xFFEF4444) : Color(0xFF8B5CF6)),
                                ),

                                // B. Glass Base (Outer container for the gate)
                                ValueListenableBuilder<AppearanceMode>(
                                  valueListenable: SettingsService().appearanceMode,
                                  builder: (context, mode, _) {
                                    final isSharp = mode == AppearanceMode.sharp;
                                    final double radius = isSharp ? 0.0 : 100.0; // 100 for circle (since w=200)

                                    return Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(radius),
                                        border: _isRedAlert 
                                          ? Border.all(color: Color(0xFFEF4444).withOpacity(0.5), width: 2)
                                          : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _isRedAlert 
                                              ? Color(0xFFEF4444).withOpacity(0.2)
                                              : Color(0xFF7C3AED).withOpacity(0.1),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          )
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(radius),
                                        child: BackdropFilter(
                                          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
                                          child: Container(color: Colors.transparent),
                                        ),
                                      ),
                                    );
                                  }
                                ),

                                // C. Progress Ring (Gradient Fill)
                                AnimatedBuilder(
                                  animation: _fillAnimation,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: Size(200, 200),
                                      painter: _ProgressRingPainter(
                                        progress: _fillAnimation.value,
                                        isRed: _isRedAlert,
                                      ),
                                    );
                                  },
                                ),

                                // D. Profile Photo (Center)
                                ValueListenableBuilder<AppearanceMode>(
                                  valueListenable: SettingsService().appearanceMode,
                                  builder: (context, mode, _) {
                                    final isSharp = mode == AppearanceMode.sharp;
                                    final double radius = isSharp ? 0.0 : 60.0; // 60 for circle (since height is 120)

                                    return ValueListenableBuilder<String?>(
                                      valueListenable: SettingsService().profileImagePath,
                                      builder: (context, path, _) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(radius),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(radius),
                                            child: path != null
                                                ? (path.startsWith('http') 
                                                    ? Image.network(path, fit: BoxFit.cover) 
                                                    : Image.file(File(path), fit: BoxFit.cover))
                                                : Container(
                                                    color: Colors.grey[100],
                                                    child: Icon(Icons.person, size: 48, color: Colors.grey[400]),
                                                  ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 48),

                          // 5. Instruction / Current Intent
                          AnimatedBuilder(
                            animation: _holdController,
                            builder: (context, child) {
                              String text;
                              if (_holdController.isAnimating || _holdController.isCompleted) {
                                text = "Focusing...";
                              } else {
                                text = (_currentIntent != null && _currentIntent!.isNotEmpty)
                                    ? _currentIntent!
                                    : "Hold to Focus";
                              }
                              
                              return Column(
                                children: [
                                  Text(
                                    text,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800, 
                                      color: _isRedAlert ? Color(0xFFEF4444) : Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  if (_currentIntent != null && !_holdController.isAnimating)
                                    Padding( 
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        "Hold to update ${_selectedMode == 0 ? 'Daily' : 'Monthly'} Intent", // Dynamic Hint
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A).withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// --- WIDGETS ---

class _GlassSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;
  final bool isRedAlert;

  const _GlassSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
    required this.isRedAlert,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppearanceMode>(
      valueListenable: SettingsService().appearanceMode,
      builder: (context, mode, _) {
        final isSharp = mode == AppearanceMode.sharp;
        final double radius = isSharp ? 0.0 : 24.0;

        return Container(
          width: 250,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 125,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      colors: isRedAlert 
                        ? [Color(0xFFEF4444), Color(0xFFB91C1C)] // Red Alert Gradient
                        : [Color(0xFFEC4899), Color(0xFF8B5CF6)], // Pink-Purple Gradient
                    ),
                    boxShadow: [
                       BoxShadow(
                         color: isRedAlert 
                           ? Color(0xFFEF4444).withOpacity(0.4) 
                           : Color(0xFF8B5CF6).withOpacity(0.4),
                         blurRadius: 12,
                         offset: Offset(0, 4)
                       ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildOption(0, "Daily"),
                  _buildOption(1, "Monthly"),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildOption(int index, String label) {
    final bool isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Color(0xFF1A1A1A).withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntentOnboardingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Define Your Intent",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 24),
                
                _buildPoint(
                  "Daily & Monthly",
                  "Switch between 24-hour focus or 30-day goals. Each has its own rhythm and limit.",
                  Icons.swap_horiz_rounded,
                ),
                SizedBox(height: 16),
                _buildPoint(
                  "The Red Alert",
                  "If you exceed your set limit (e.g. ₹100 today), the interface shifts to Rose-Red to signal caution.",
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                ),
                SizedBox(height: 16),
                _buildPoint(
                  "Hold to Commit",
                  "Physical friction creates mental clarity. Hold the gate to lock in your intent.",
                  Icons.fingerprint,
                ),
                
                SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7C3AED),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "I Understand",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Widget _buildPoint(String title, String desc, IconData icon, {Color color = const Color(0xFF7C3AED)}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A).withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- PAINTERS ---

class _RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RipplePainter(this.animation, {required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Draw 3 expanding rings
    for (int i = 0; i < 3; i++) {
      final double progress = (animation.value + (i / 3.0)) % 1.0;
      final double radius = 100 + (progress * 50); // Expand from 100 to 150
      final double opacity = 1.0 - progress; // Fade out

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2; // Thin sleek lines

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => true;
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final bool isRed;

  _ProgressRingPainter({required this.progress, required this.isRed});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(
        center,
        [
          isRed ? Color(0xFFEF4444) : Color(0xFFC026D3), // Start
          isRed ? Color(0xFFB91C1C) : Color(0xFF8B5CF6), // End
        ],
        [0.0, 1.0],
        TileMode.clamp,
        -pi / 2, // Start at top
        (-pi / 2) + (progress * 2 * pi), // End angle
      );

    // Draw arc
    canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}
