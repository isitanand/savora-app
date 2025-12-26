import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart'; // Added
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';
import '../theme/core_theme.dart';
import '../widgets/core_drawer.dart';
import '../widgets/expressive_widgets.dart';
import 'entry_detail_screen.dart';
import 'reflection_entry_screen.dart';
import 'profile_screen.dart'; 
import '../data/settings_service.dart';
import '../logic/insight_engine.dart'; // Added
import '../data/models/insight_model.dart'; // Added
import '../widgets/insight_card.dart'; // Added
import '../widgets/glass_onboarding_dialog.dart';

class DailyStreamScreen extends StatefulWidget {
  DailyStreamScreen({super.key});

  State<DailyStreamScreen> createState() => _DailyStreamScreenState();
}

class _DailyStreamScreenState extends State<DailyStreamScreen> {
  late Future<List<ReflectionEntry>> _entriesFuture;
  final PageController _pageController = PageController();
  int _activeGraphPage = 0;

  int _insightType = 0; // 0: Budget, 1: Rhythm, 2: Pattern, 3: Motivation
  List<Insight> _currentInsights = []; // Added for Insight System

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    _loadEntries();
    
    // Pick a DIFFERENT insight style than last time
    final last = SettingsService().lastInsightIndex.value;
    _insightType = (last + 1) % 4; // Guaranteed simple rotation [0,1,2,3]
    SettingsService().setLastInsightIndex(_insightType);

    // Listen to Tone Changes
    SettingsService().insightTone.addListener(_onToneChanged);

    // Check Onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenHomeOnboarding.value) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GlassOnboardingDialog(
            title: "Your Daily Stream",
            description: "A living record of your financial flow.\n\nEvery entry tells a story. Pull down to refresh, tap to explore.",
            icon: Icons.water_drop_rounded, // or stream_rounded
            accentColor: Color(0xFFE91E63), // Pink Accent
            onDismiss: () {
              Navigator.pop(context);
              SettingsService().setHasSeenHomeOnboarding(true);
            },
          ),
        );
      }
    });
  }

  void _onToneChanged() {
    _loadEntries();
  }

  @override
  void dispose() {
    SettingsService().insightTone.removeListener(_onToneChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _loadEntries() {
    // UPDATED: Chain analysis after fetching
    final future = DataService().repository.getEntries();
    setState(() {
      _entriesFuture = future.then((entries) {
        if (mounted) {
          // Analyze ALL entries for deep patterns
          // Analyze ALL entries for deep patterns
          final allInsights = InsightEngine().analyze(entries);
          
          // STRICT ROTATION LOGIC
          // 1. Check if we need to reset history (New Day Logic)
          final lastDateStr = SettingsService().lastInsightDate.value; // Need to add this to SettingsService first
          final todayStr = DateTime.now().toIso8601String().split('T').first;
          
          if (lastDateStr != todayStr) {
             SettingsService().clearHistory();
             SettingsService().setLastInsightDate(todayStr); 
          }

          final history = SettingsService().dailyInsightHistory.value;
          Insight? selected;

          if (allInsights.isNotEmpty) {
             // 2. Filter out already seen insights for today
             var candidates = allInsights.where((i) => !history.contains(i.message)).toList();
             
             // 3. Fallback: If we've seen everything, reset history to start fresh loop (or just show random)
             if (candidates.isEmpty) {
                SettingsService().clearHistory();
                candidates = allInsights; 
             }
             
             // 4. Select random candidate to ensure variety even among fresh batch
             // (Or stick to type prioritisation if preferred, but random is safer for "not same twice")
             if (candidates.isNotEmpty) {
               selected = candidates[DateTime.now().millisecond % candidates.length];
             }
             
             // 5. Save this new selection
             if (selected != null) {
                SettingsService().addToHistory(selected.message);
                SettingsService().setLastInsightMessage(selected.message); // Still useful for reference
                _currentInsights = [selected];
             }
          }
        }
        return entries;
      });
    });
  }



  DateTime _viewDate = DateTime.now(); // Mandate: _viewDate for view state
  double globalNetFlow = 0.0; // Mandate: Defined variable

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewDate, // Use _viewDate
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF9C27B0), // Purple
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              secondary: Color(0xFFE91E63), // Pink accent
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF9C27B0), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && !_isSameDay(picked, _viewDate)) {
      setState(() {
        _viewDate = picked;
      });
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReflectionEntryScreen()),
    );
    if (result == true) {
      _loadEntries();
    }
  }

  Map<String, dynamic> _calculateFinancials(List<ReflectionEntry> entries, DateTime displayDate) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    final monthEntries = entries.where((e) => 
      e.timestamp.year == currentMonth.year && 
      e.timestamp.month == currentMonth.month
    ).toList();

    final netFlow = monthEntries.where((e) => e.amount < 0).fold<double>(0, (sum, e) => sum + e.amount.abs());
    
    // Mandate: Fix logic to use .map().reduce() as requested
    // Mandate: Update: Exclude 'Favor' context (Assets != Expenses)
    
    // 1. Filter out Favors from financial totals (but keep in the list for display if needed? 
    //    Actually, method receives 'entries'. filtering strictly for calcs.)
    final calcEntries = entries.where((e) => e.context != 'Favor').toList();
    final calcMonthEntries = monthEntries.where((e) => e.context != 'Favor').toList();

    // Mandate: Global Net Flow (Sum of all NON-FAVOR entries)
    final globalNetFlow = calcEntries.isEmpty 
        ? 0.0 
        : calcEntries.map((e) => e.amount).reduce((a, b) => a + b);

    // Mandate: Total Spent calculation based on _viewDate (excluding Favors)
    final viewDateEntries = calcEntries.where((e) => _isSameDay(e.timestamp, _viewDate)).toList();
    final totalSpentToday = viewDateEntries.isEmpty 
        ? 0.0 
        : viewDateEntries.map((e) => e.amount.abs()).reduce((a, b) => a + b);

    final weeklyData = _calculateWeeklyData(calcEntries); // Also update weekly data

    return <String, dynamic>{
      'netFlow': globalNetFlow, 
      'entryCount': monthEntries.length, // Total count can still include favors? User might want to see them in list. 
                                         // But for financials, we use excluded.
                                         // Let's keep entryCount as "Activity Count" (includes favors).
      'dailyFlow': _generateCumulativeTrend(entries), // visual trend might still show them? Maybe exclude?
                                                      // Let's exclude from trend for consistency.
      'totalSpentToday': totalSpentToday,
      'thisWeek': weeklyData['thisWeek'],
      'lastWeek': weeklyData['lastWeek'],
      'currentMonthSpend': globalNetFlow.abs(), 
    };
  }

  Map<String, List<double>> _calculateWeeklyData(List<ReflectionEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(Duration(days: 7));

    List<double> thisWeek = List.filled(7, 0.0);
    List<double> lastWeek = List.filled(7, 0.0);

    for (var e in entries) {
      final diffThis = e.timestamp.difference(thisWeekStart).inDays;
      if (diffThis >= 0 && diffThis < 7) {
        thisWeek[diffThis] += e.amount.abs();
      }
      final diffLast = e.timestamp.difference(lastWeekStart).inDays;
      if (diffLast >= 0 && diffLast < 7) {
        lastWeek[diffLast] += e.amount.abs();
      }
    }
    return {'thisWeek': thisWeek, 'lastWeek': lastWeek};
  }

  // Mandate: Generate Monthly Velocity Data (Current Month Only, Day 1-31)
  List<double> _generateCumulativeTrend(List<ReflectionEntry> entries) {
    print('--- GENERATING TREND DEBUG ---');
    final now = DateTime.now();
    // Use local time for consistent day matching
    final currentMonth = DateTime(now.year, now.month);
    
    // Filter entries for CURRENT MONTH only
    final monthEntries = entries.where((e) => 
      e.timestamp.year == currentMonth.year && 
      e.timestamp.month == currentMonth.month
    ).toList();
    
    print('Found ${monthEntries.length} entries for ${now.month}/${now.year}');
    
    // Create array for all 31 days
    final dailySpending = List<double>.filled(31, 0.0);
    
    // Calculate daily spending for each day
    for (var entry in monthEntries) {
      final dayIndex = entry.timestamp.day - 1; // Day 1 = index 0
      
      if (dayIndex >= 0 && dayIndex < 31) {
        dailySpending[dayIndex] += entry.amount.abs();
        print('Added ${entry.amount.abs()} to Day ${dayIndex + 1}');
      } else {
        print('WARNING: Entry date ${entry.timestamp} out of range!');
      }
    }
    
    return dailySpending;
  }

  String? _calculateSpendingMood(List<ReflectionEntry> entries) {
    // Mandate: Calculate most frequent mood associated with spending
    // Assumption: All entries are spending
    final expenses = entries; 
    if (expenses.isEmpty) return null;

    final moodSpending = <String, double>{};
    for (var e in expenses) {
       final mood = e.mood; 
       moodSpending[mood] = (moodSpending[mood] ?? 0) + e.amount.abs();
    }
    
    if (moodSpending.isEmpty) return null;

    var maxMood = "";
    var maxAmount = -1.0;
    moodSpending.forEach((mood, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        maxMood = mood;
      }
    });
    
    if (maxMood.isEmpty) return null;
    return "Most spending happened when you felt $maxMood.";
  }

  // Helpers removed per mandate


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SettingsService().monthlyLimit,
        SettingsService().insightTone,
        SettingsService().appearanceMode,
        SettingsService().insightsEnabled,
        SettingsService().userName,
        SettingsService().profileImagePath,
      ]),
      builder: (context, _) {
       final monthlyLimit = SettingsService().monthlyLimit.value;

       final appearance = SettingsService().appearanceMode.value;
       final tone = SettingsService().insightTone.value; // Mandate: Get Tone
    
    return Scaffold(
      drawer: CoreDrawer(),
      floatingActionButton: UnifiedProButton(
          text: "New Entry",
          onTap: _navigateToAdd,
          gradientColors: [
             Color(0xFFBB86FC).withOpacity(0.6), // Mandate: Specific Gradient
             Color(0xFFCF6679).withOpacity(0.6)
          ],
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Stack(
        children: [
          // 1. LIGHT BASE (Mandate)
          Container(
            color: Color(0xFFFDFCFE), // Off-white
          ),
          
          // 2. ATMOSPHERIC ORBS (Lavender, Pink, Cyan)
          // Top-Left: Lavender
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
          
          // Right-Center: Soft Pink
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

          // Bottom-Left: Cyan
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
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50), // Mandate: 50
              child: Container(
                color: Colors.white.withOpacity(0.1), // Subtle white wash
              ),
            ),
          ),
          // CONTENT
          FutureBuilder<List<ReflectionEntry>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];
              final displayDate = _viewDate; // Mandate: Use _viewDate state
              
              // Mandate: Update Global Net Flow Logic (Safe calculation)
              // We calculate here but DO NOT setState() to avoid build error.
              // Instead, we assign to a local variable that SHADOWS the class member if needed,
              // or updates the class member if not building? No, side-effects bad.
              // We will just define a local variable 'globalNetFlow' for the UI to use.
              // But to satisfy "Ensure globalNetFlow references are backed by a defined variable",
              // we have the class member. We will use a local final variable here:
              final globalNetFlowVal = entries.isEmpty 
                  ? 0.0 
                  : entries.map((e) => e.amount).reduce((a, b) => a + b); // Signed Sum
              
              final financials = _calculateFinancials(entries, displayDate);
              
              final netFlow = financials['netFlow'] as double;
              final entryCount = financials['entryCount'] as int;
              final dailyFlow = financials['dailyFlow'] as List<double>;
              final totalSpentToday = financials['totalSpentToday'] as double;
              final thisWeek = financials['thisWeek'] as List<double>;
              final lastWeek = financials['lastWeek'] as List<double>;
              final currentMonthSpend = financials['currentMonthSpend'] as double;
              final remainingAmount = monthlyLimit - currentMonthSpend; // Mandate: Remaining Logic
              
            // Mandate: Calculate Insight early
            // Tone logic:
            final tone = SettingsService().insightTone.value;
            String insightText = "";
            if (SettingsService().insightsEnabled.value) {
               if (tone == 'Supportive') {
                 insightText = "You're doing great! Keep tracking."; // Simplified placeholder logic
               } else if (tone == 'Analytical') {
                 insightText = "Spending velocity: Normal. Trend: Stable.";
               } else {
                 insightText = "Total spent today: ₹${totalSpentToday.toStringAsFixed(0)}.";
               }
            }

            final spendingInsight = _calculateSpendingMood(entries);

            // Insights Logic Removed per mandate


            final displayDateFixed = displayDate; // Alias
            final displayedEntries = entries.where((e) => _isSameDay(e.timestamp, displayDateFixed)).toList();
            
            // Rhythm Data (Last 7 Days)
            final now = DateTime.now();
            // final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

            return CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                // Transparent AppBar for structure
                SliverAppBar(
                  floating: false,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                ),
                
                // ---------------------------------------------------------
                // SECTION 1: FINANCIAL HERO
                // ---------------------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar: Menu + Profile
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (context) => IconButton(
                                icon: Icon(Icons.menu_rounded, color: CoreTheme.deepInk, size: 28),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 24, 
                                  backgroundColor: Colors.white,
                                  backgroundImage: SettingsService().profileImagePath.value != null 
                                      ? (kIsWeb 
                                          ? NetworkImage(SettingsService().profileImagePath.value!) 
                                          : FileImage(File(SettingsService().profileImagePath.value!)) as ImageProvider)
                                      : null,
                                  child: SettingsService().profileImagePath.value == null 
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 28,
                                          color: CoreTheme.deepInk,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                        
                // TOTAL NET FLOW (Mandate: Restored to match perfect layout)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Net Flow",
                          style: TextStyle(
                            color: Color(0xFF1A1A1A).withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4), 
                        Text(
                          '₹${netFlow.abs().toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 42, 
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(height: 8), // Spacing
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: 1.1, // Mandate: 1.1 spacing
                            ),
                            children: [
                              TextSpan(
                                text: "Remaining: ",
                                style: TextStyle(fontWeight: FontWeight.w600), // Mandate: w600
                              ),
                              TextSpan(
                                text: "₹${remainingAmount.toStringAsFixed(2)}",
                                style: TextStyle(fontWeight: FontWeight.w700), // Mandate: w700
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // NEW INSIGHTS SYSTEM
                if (_currentInsights.isNotEmpty)
                   SliverPadding(
                     // UPDATED Spacing: More top padding (16) to clear the header visually
                     padding: EdgeInsets.fromLTRB(24, 16, 24, 4), 
                     sliver: SliverToBoxAdapter(
                       child: InsightCard(insight: _currentInsights.first),
                     ),
                   ),

                SliverToBoxAdapter(child: SizedBox(height: 24)), // Mandate: 24 Margin

                // CHART SECTION or EMPTY STATE
                if (entries.length < 3)
                   SliverToBoxAdapter(
                     child: Container(
                       height: 200,
                       margin: EdgeInsets.symmetric(horizontal: 24),
                       decoration: BoxDecoration(
                         color: Colors.white.withValues(alpha: 0.3),
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                       ),
                       child: Center(
                         child: Padding(
                           padding: EdgeInsets.all(24),
                           child: Text(
                             "Insights will appear once you log 3 moments. What influenced your spending today?",
                             textAlign: TextAlign.center,
                             style: GoogleFonts.plusJakartaSans(
                               color: CoreTheme.deepInk.withValues(alpha: 0.6),
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ),
                       ),
                     ),
                   )
                else
                SliverPadding(
                   padding: EdgeInsets.symmetric(horizontal: 20),
                   sliver: SliverToBoxAdapter(
                     child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: Offset(0, 10)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  // View Indicator Bar (Transparent to Violet)
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _activeGraphPage == 0 ? Color(0xFFEC4899) : Colors.transparent, // Pink
                                          _activeGraphPage == 1 ? Color(0xFF8B5CF6) : Colors.transparent, // Purple
                                        ],
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(24, 24, 24, 0), // Increased global padding
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onLongPress: () {
                                          showDialog(
                                            context: context, 
                                            builder: (ctx) => AlertDialog(
                                              title: Text("Graph Debug Data"),
                                              content: SingleChildScrollView(
                                                child: Text(
                                                  "Month Entries: ${entries.where((e) => e.timestamp.month == DateTime.now().month && e.timestamp.year == DateTime.now().year).length}\n\n"
                                                  "Daily Data:\n" + 
                                                  _generateCumulativeTrend(entries)
                                                    .asMap().entries
                                                    .where((e) => e.value > 0)
                                                    .map((e) => "Day ${e.key + 1}: ${e.value}")
                                                    .join("\n")
                                                ),
                                              ),
                                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close"))],
                                            )
                                          );
                                        },
                                        child: Text(
                                          _activeGraphPage == 0 ? "Monthly Velocity" : "Weekly Spend",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _activeGraphPage == 0 ? "Day 1 - 31" : "Comparison",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1A1A).withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  height: 200, 
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (i) => setState(() => _activeGraphPage = i),
                                    children: [
                                      // VIEW 1: MONTHLY VELOCITY
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: InsightGraph(
                                          data: dailyFlow.isEmpty ? [0] : dailyFlow,
                                          color: Color(0xFFEC4899),
                                          targetLimit: monthlyLimit, // Mandate: Pass actual monthly limit
                                          todayIndex: now.day - 1,
                                          isMonthly: true,
                                        ),
                                      ),
                                      // VIEW 2: WEEKLY BAR CHART
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: WeeklyBarChart(
                                          thisWeek: thisWeek,
                                          lastWeek: lastWeek,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                     ),
                   ),
                 ),

                SliverToBoxAdapter(child: SizedBox(height: 24)), // Mandate: 24 Margin

                // METRIC CARDS (Reference-aligned)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Mandate: 12.0 vertical
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (entries.isNotEmpty) {
                                final highest = entries.reduce((a, b) => a.amount.abs() > b.amount.abs() ? a : b);
                                final result = await Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: highest))
                                );
                                if (result == true) {
                                  _loadEntries();
                                }
                              }
                            },
                            child: _MetricCard(
                              icon: Icons.arrow_upward_rounded,
                              iconColor: Color(0xFFEC4899),
                              label: "Highest Entry",
                              value: entries.isEmpty ? "₹0" : "₹${entries.map((e) => e.amount.abs()).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}",
                              subtitle: "Tap for details", // Updated subtitle to indicate action
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.receipt_long_rounded,
                            iconColor: Color(0xFF8B5CF6),
                            label: "Total Entries",
                            value: "${entries.where((e) => e.timestamp.month == DateTime.now().month && e.timestamp.year == DateTime.now().year).length}", // Mandate: This month only
                            subtitle: "This month", // Mandate: Changed from "Lifetime"
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                // ---------------------------------------------------------
                // SECTION 3: DAILY STREAM (Total Spent Header)
                // ---------------------------------------------------------
                // ---------------------------------------------------------
                // SECTION 3: TARGET PROGRESS BAR (Replacing Net Flow)
                // ---------------------------------------------------------
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverToBoxAdapter(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         // Progress Bar
                         ClipRRect(
                           borderRadius: BorderRadius.circular(4),
                           child: Container(
                             height: 4,
                             width: double.infinity,
                             child: LayoutBuilder(
                               builder: (context, constraints) {
                                 final double rawProgress = (monthlyLimit > 0) ? (currentMonthSpend / monthlyLimit) : 0.0;
                                 final double progress = rawProgress.clamp(0.0, 1.0);
                                 final bool isOverLimit = rawProgress > 1.0;

                                 return Stack(
                                   children: [
                                     Container(color: Colors.grey.withValues(alpha: 0.1)), // Track
                                     FractionallySizedBox(
                                       widthFactor: progress,
                                       child: Container(
                                         decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isOverLimit 
                                                ? [Color(0xFFFF512F), Color(0xFFDD2476)] // Vibrant Red-to-Orange (Red Alert)
                                                : [Color(0xFFEC4899), Color(0xFF8B5CF6)], // Pink to Purple Gradient
                                            ),
                                         ),
                                       ),
                                     ),
                                   ],
                                 );
                               },
                             ),
                           ),
                         ),
                         SizedBox(height: 8),
                         // Sub-labels
                         Builder(
                           builder: (context) {
                             final bool isOverLimit = currentMonthSpend > monthlyLimit;
                             final double overage = (currentMonthSpend - monthlyLimit).abs();
                             
                             return Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(
                                   "₹${currentMonthSpend.toStringAsFixed(0)} spent",
                                   style: GoogleFonts.plusJakartaSans(
                                     fontSize: 10,
                                     fontWeight: FontWeight.w300,
                                     color: CoreTheme.deepInk.withValues(alpha: 0.6),
                                   ),
                                 ),
                                 Text(
                                   isOverLimit 
                                      ? "Overspent: ₹${overage.toStringAsFixed(0)}" 
                                      : "₹${remainingAmount.toStringAsFixed(0)} left",
                                   style: GoogleFonts.plusJakartaSans(
                                     fontSize: 10,
                                     fontWeight: isOverLimit ? FontWeight.w700 : FontWeight.w300, // Bold if overspent
                                     color: isOverLimit ? Colors.redAccent : CoreTheme.deepInk.withValues(alpha: 0.6), // Red if overspent
                                   ),
                                 ),
                               ],
                             );
                           }
                         ),
                       ],
                     ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 20)),

                // SECTION: Insights System (Premium Glass Card)


                // SECTION: Financial Hero (Budget + Net Flow)day Header (Strict Mandate)
                SliverPadding(
                   padding: EdgeInsets.symmetric(horizontal: 24),
                   sliver: SliverToBoxAdapter(
                     child: Column(
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                              Text(
                                "Total Spent: ₹${totalSpentToday.abs().toStringAsFixed(2)}", 
                                style: GoogleFonts.plusJakartaSans( 
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600, // Mandate: w600
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Container(
                                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.5),
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(color: Colors.white, width: 1.0),
                                 ),
                                 child: InkWell(
                                   onTap: () => _selectDate(context),
                                   child: Row(
                                     children: [
                                       Text(
                                          DateFormat('MMM d').format(_viewDate),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                       ),
                                       SizedBox(width: 8),
                                       Icon(
                                         Icons.calendar_today_outlined, 
                                         size: 18, 
                                         color: Color(0xFF1A1A1A),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                           ],
                         ),
                         SizedBox(height: 16), // Mandate: Exactly 16 spacing
                         
                          // Today Pill with Violet Line inline
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE3D5FF).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _isSameDay(_viewDate, DateTime.now()) 
                                        ? "TODAY" 
                                        : DateFormat('MMM d').format(_viewDate).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.purple.withOpacity(0.8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12), // Spacing between pill and line
                                // MANDATE: Thin Violet Line (1.5px divider inline with TODAY)
                                Expanded(
                                  child: Container(
                                    height: 1.5, // Mandate: 1.5px height
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6).withOpacity(0.5), // Mandate: 0.5 opacity
                                          Color(0xFFD946EF).withOpacity(0.5), // Mandate: 0.5 opacity
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12), // Mandate: 12px spacing to first entry
                       ],
                     ),
                   ),
                ),

                if (snapshot.connectionState == ConnectionState.waiting)
                   SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (entries.isEmpty)
                   SliverFillRemaining(
                     child: Center(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(Icons.waves, size: 48, color: CoreTheme.softGraphite.withOpacity(0.3)),
                           SizedBox(height: 16),
                           Text("Begin your stream.", style: TextStyle(color: CoreTheme.softGraphite)),
                         ],
                       ),
                     ),
                   )
                else
                   SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final viewDateEntries = displayedEntries;
                          if (index >= viewDateEntries.length) return null;
                          final entry = viewDateEntries[index];

                          return Padding(
                            padding: EdgeInsets.only(bottom: 20), // Mandate: 20px gap for "Air-Glass" breathability
                            child: _ElevatedEntryCard(
                              entry: entry,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
                                );
                                if (result == true) {
                                  _loadEntries();
                                }
                              },
                              getIcon: _getCategoryIcon,
                            ),
                          );
                        },
                        childCount: displayedEntries.length,
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
            },
          ),
        ],
      ),
    );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    if (_isSameDay(date, DateTime.now())) return "Today";
    if (_isSameDay(date, DateTime.now().subtract(Duration(days: 1)))) return "Yesterday";
    return DateFormat('MMM d').format(date);
  }

  IconData _getCategoryIcon(String context) {
    switch (context.toLowerCase()) {
      case 'travel':
        return Icons.flight_takeoff_outlined; // Travel
      case 'food/cafe':
      case 'food':
      case 'cafe':
        return Icons.local_cafe_outlined; // Cafe
      case 'social':
        return Icons.people_outline_rounded; // Social
      case 'work':
        return Icons.work_outline_rounded; // Work
      case 'shopping':
        return Icons.shopping_bag_outlined; // Shopping
      case 'home':
        return Icons.home_outlined; // Home
      case 'impulsive':
        return Icons.bolt_rounded; // Impulsive
      default:
        return Icons.receipt_long_outlined; // Default
    }
  }
}

class _ElevatedEntryCard extends StatelessWidget {
  final ReflectionEntry entry;
  final VoidCallback onTap;
  final IconData Function(String) getIcon;

  const _ElevatedEntryCard({
    Key? key,
    required this.entry,
    required this.onTap,
    required this.getIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16, // Mandate: Reduced by another 10% (18 -> 16)
                backgroundColor: Colors.grey.withOpacity(0.08), // Soft-grey glass circle
                child: Icon(
                  getIcon(entry.context),
                  color: Colors.black.withOpacity(0.7),
                  size: 18, // Mandate: Reduced by another 10% (20 -> 18)
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.note.isNotEmpty ? entry.note : entry.context,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 6), // Added breathability
                      Text(
                        // Logic: Keep default spacing even if empty
                        () {
                          final time = DateFormat('h:mm a').format(entry.timestamp);
                          final mood = entry.mood.isEmpty ? "     " : entry.mood; // 5 spaces for empty
                          final context = entry.context.isEmpty ? "     " : entry.context; // 5 spaces for empty
                          return "$time   •   $mood   •   $context";
                        }(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: CoreTheme.deepInk.withOpacity(0.85), 
                          fontWeight: FontWeight.w500, 
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₹${entry.amount.abs().toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A), // Mandate: Strictly #1A1A1A
                ),
              ),
            ],
          ),
        ), // End InkWell
        SizedBox(height: 20), // Mandate: 20px spacing between tiles for breathability
      ],
    );
  }
}
// End of _ElevatedEntryCard


class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Mandate: Appearance Mode Logic
    final appearance = SettingsService().appearanceMode.value;
    final isSoft = appearance == AppearanceMode.soft;

    return Container(
      padding: EdgeInsets.all(20), // Mandate: 20px padding
      decoration: BoxDecoration(
        color: isSoft ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(isSoft ? 24 : 8),
        border: Border.all(
          // Mandate: Gradient Border (subtle glow)
          color: iconColor.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          // Mandate: JEWELRY GLOW - Large blur (30.0) with low opacity (0.05)
          BoxShadow(
            color: iconColor.withOpacity(0.05),
            blurRadius: 30.0, // Mandate: 30.0 for floating effect
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // GHOST ICON - Top-right corner with opacity 0.3
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              icon,
              size: 20, // Mandate: 20px icon
              color: iconColor.withOpacity(0.9), // Mandate: 0.9 opacity for visibility
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LABEL
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, // Mandate: 12
                  fontWeight: FontWeight.w300, // Mandate: w300
                  color: Color(0xFF1A1A1A).withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 4),
              // VALUE - Increased to 24px
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, // Mandate: 24px (increased from 22)
                  fontWeight: FontWeight.w700, // Mandate: w700
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              // SUBTITLE - Lighter w300
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans( // Mandate: Use GoogleFonts
                   fontSize: 10,
                   color: Color(0xFF1A1A1A).withOpacity(0.5),
                   fontWeight: FontWeight.w300, // Mandate: w300
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
