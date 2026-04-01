import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart'; 
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';
import '../theme/core_theme.dart';
import '../widgets/core_drawer.dart';
import '../widgets/expressive_widgets.dart';
import 'entry_detail_screen.dart';
import 'reflection_entry_screen.dart';
import 'profile_screen.dart'; 
import '../data/settings_service.dart';
import '../logic/insight_engine.dart'; 
import '../data/models/insight_model.dart'; 
import '../widgets/insight_card.dart'; 
import '../widgets/glass_onboarding_dialog.dart';

class DailyStreamScreen extends StatefulWidget {
  DailyStreamScreen({super.key});

  State<DailyStreamScreen> createState() => _DailyStreamScreenState();
}

class _DailyStreamScreenState extends State<DailyStreamScreen> {
  late Future<List<ReflectionEntry>> _entriesFuture;
  final PageController _pageController = PageController();
  int _activeGraphPage = 0;

  int _insightType = 0; 
  List<Insight> _currentInsights = []; 

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    _loadEntries();
    
    
    final last = SettingsService().lastInsightIndex.value;
    _insightType = (last + 1) % 4; 
    SettingsService().setLastInsightIndex(_insightType);

    
    SettingsService().insightTone.addListener(_onToneChanged);

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenHomeOnboarding.value) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GlassOnboardingDialog(
            title: "Your Daily Stream",
            description: "A living record of your financial flow.\n\nEvery entry tells a story. Pull down to refresh, tap to explore.",
            icon: Icons.water_drop_rounded, 
            accentColor: Color(0xFFE91E63), 
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
    
    final future = DataService().repository.getEntries();
    setState(() {
      _entriesFuture = future.then((entries) {
        if (mounted) {
          
          
          final allInsights = InsightEngine().analyze(entries);
          
          
          
          final lastDateStr = SettingsService().lastInsightDate.value; 
          final todayStr = DateTime.now().toIso8601String().split('T').first;
          
          if (lastDateStr != todayStr) {
             SettingsService().clearHistory();
             SettingsService().setLastInsightDate(todayStr); 
          }

          final history = SettingsService().dailyInsightHistory.value;
          Insight? selected;

          if (allInsights.isNotEmpty) {
             
             var candidates = allInsights.where((i) => !history.contains(i.message)).toList();
             
             
             if (candidates.isEmpty) {
                SettingsService().clearHistory();
                candidates = allInsights; 
             }
             
             
             
             if (candidates.isNotEmpty) {
               selected = candidates[DateTime.now().millisecond % candidates.length];
             }
             
             
             if (selected != null) {
                SettingsService().addToHistory(selected.message);
                SettingsService().setLastInsightMessage(selected.message); 
                _currentInsights = [selected];
             }
          }
        }
        return entries;
      });
    });
  }



  DateTime _viewDate = DateTime.now(); 
  double globalNetFlow = 0.0; 

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewDate, 
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF9C27B0), 
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              secondary: Color(0xFFE91E63), 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF9C27B0), 
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

    final calcEntries = entries.where((e) => e.context != 'Favor').toList();
    final calcMonthEntries = monthEntries.where((e) => e.context != 'Favor').toList();

    final totalExpenses = calcMonthEntries.where((e) => e.amount < 0).fold<double>(0, (sum, e) => sum + e.amount.abs());
    final totalIncome = calcMonthEntries.where((e) => e.amount > 0).fold<double>(0, (sum, e) => sum + e.amount);

    final viewDateEntries = calcEntries.where((e) => _isSameDay(e.timestamp, _viewDate)).toList();
    final totalSpentToday = viewDateEntries.isEmpty 
        ? 0.0 
        : viewDateEntries.map((e) => e.amount.abs()).reduce((a, b) => a + b);

    final weeklyData = _calculateWeeklyData(calcEntries); 

    return <String, dynamic>{
      'entryCount': monthEntries.length, 
      'dailyFlow': _generateCumulativeTrend(entries), 
      'totalSpentToday': totalSpentToday,
      'thisWeek': weeklyData['thisWeek'],
      'lastWeek': weeklyData['lastWeek'],
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
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

  
  List<double> _generateCumulativeTrend(List<ReflectionEntry> entries) {
    print('--- GENERATING TREND DEBUG ---');
    final now = DateTime.now();
    
    final currentMonth = DateTime(now.year, now.month);
    
    
    final monthEntries = entries.where((e) => 
      e.timestamp.year == currentMonth.year && 
      e.timestamp.month == currentMonth.month
    ).toList();
    
    print('Found ${monthEntries.length} entries for ${now.month}/${now.year}');
    
    
    final dailySpending = List<double>.filled(31, 0.0);
    
    
    for (var entry in monthEntries) {
      final dayIndex = entry.timestamp.day - 1; 
      
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
       final tone = SettingsService().insightTone.value; 
    
    return Scaffold(
      drawer: CoreDrawer(),
      floatingActionButton: UnifiedProButton(
          text: "New Entry",
          onTap: _navigateToAdd,
          gradientColors: [
             Color(0xFFBB86FC).withOpacity(0.6), 
             Color(0xFFCF6679).withOpacity(0.6)
          ],
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Stack(
        children: [
          
          Container(
            color: Color(0xFFFDFCFE), 
          ),
          
          
          
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
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50), 
              child: Container(
                color: Colors.white.withOpacity(0.1), 
              ),
            ),
          ),
          
          FutureBuilder<List<ReflectionEntry>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];
              final displayDate = _viewDate; 
              
              
              
              
              
              
              
              
              final globalNetFlowVal = entries.isEmpty 
                  ? 0.0 
                  : entries.map((e) => e.amount).reduce((a, b) => a + b); 
              
              final financials = _calculateFinancials(entries, displayDate);
              
              final entryCount = financials['entryCount'] as int;
              final dailyFlow = financials['dailyFlow'] as List<double>;
              final totalSpentToday = financials['totalSpentToday'] as double;
              final thisWeek = financials['thisWeek'] as List<double>;
              final lastWeek = financials['lastWeek'] as List<double>;
              final totalExpenses = financials['totalExpenses'] as double;
              final totalIncome = financials['totalIncome'] as double;
              
              
              final nowDate = DateTime.now();
              final daysInMonth = DateUtils.getDaysInMonth(nowDate.year, nowDate.month);
              final daysLeft = daysInMonth - nowDate.day;
              final remainingAmount = monthlyLimit - totalExpenses;
              final dailyRequired = daysLeft > 0 ? (remainingAmount / daysLeft) : 0.0;
              
            
            
            final tone = SettingsService().insightTone.value;
            String insightText = "";
            if (SettingsService().insightsEnabled.value) {
               if (tone == 'Supportive') {
                 insightText = "You're doing great! Keep tracking."; 
               } else if (tone == 'Analytical') {
                 insightText = "Spending velocity: Normal. Trend: Stable.";
               } else {
                 insightText = "Total spent today: ₹${totalSpentToday.toStringAsFixed(0)}.";
               }
            }

            final spendingInsight = _calculateSpendingMood(entries);

            


            final displayDateFixed = displayDate; 
            final displayedEntries = entries.where((e) => _isSameDay(e.timestamp, displayDateFixed)).toList();
            
            
            final now = DateTime.now();
            

            return CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                
                SliverAppBar(
                  floating: false,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                ),
                
                
                
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 4), // Added top breathing space and slight bottom buffer
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
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
                        
                
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalIncome > 0 ? "Current Balance" : "Total Spending This Month",
                          style: TextStyle(
                            color: Color(0xFF1A1A1A).withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4), 
                        Text(
                          totalIncome > 0 
                              ? '₹${(totalIncome - totalExpenses).toStringAsFixed(2)}'
                              : '₹${totalExpenses.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 42, 
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -1.0,
                          ),
                        ),
                        if (_currentInsights.isNotEmpty) ...[
                          SizedBox(height: 16),
                          InsightCard(insight: _currentInsights.first),
                        ],
                      ],
                    ),
                  ),
                ),
                
                if (entries.isNotEmpty) ...[
                  SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _activeGraphPage = index;
                                });
                              },
                              children: [
                                // Page 1: Monthly Trend
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                                      child: Container(
                                        clipBehavior: Clip.antiAlias,
                                        width: double.infinity,
                                        padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Monthly Trend",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                                Text(
                                                  "Day 1 - 31",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1A1A1A).withOpacity(0.4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 24),
                                            Expanded(
                                              child: InsightGraph(
                                                data: dailyFlow.isEmpty ? [0] : dailyFlow,
                                                color: Color(0xFFEC4899),
                                                targetLimit: monthlyLimit, 
                                                todayIndex: now.day - 1,
                                                isMonthly: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Page 2: Weekly Spend
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Weekly Spend",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Expanded(child: WeeklyBarChart(thisWeek: thisWeek, lastWeek: lastWeek)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(2, (index) {
                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                height: 6,
                                width: _activeGraphPage == index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: _activeGraphPage == index 
                                      ? Color(0xFF8B5CF6) 
                                      : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (entries.isEmpty) ...[
                   SliverToBoxAdapter(
                     child: Container(
                       height: 200,
                       margin: EdgeInsets.symmetric(horizontal: 24),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.3),
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: Colors.white.withOpacity(0.5)),
                       ),
                       child: Center(
                         child: Padding(
                           padding: EdgeInsets.all(24),
                           child: Text(
                             "No entries yet.\nAdd your first stream to start tracking.",
                             textAlign: TextAlign.center,
                             style: GoogleFonts.plusJakartaSans(
                               color: CoreTheme.deepInk.withOpacity(0.6),
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ),
                       ),
                     ),
                   )
                ],

                SliverToBoxAdapter(child: SizedBox(height: 24)), 

                
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
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
                              subtitle: "Tap for details", 
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.receipt_long_rounded,
                            iconColor: Color(0xFF8B5CF6),
                            label: "Total Entries",
                            value: "${entries.where((e) => e.timestamp.month == DateTime.now().month && e.timestamp.year == DateTime.now().year).length}", 
                            subtitle: "This month", 
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                
                
                
                
                
                
                SliverPadding(
                   padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
                   sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           Text(
                             "Savings Goal",
                             style: GoogleFonts.plusJakartaSans(
                               fontSize: 16,
                               fontWeight: FontWeight.w700,
                               color: Color(0xFF1A1A1A),
                             ),
                           ),
                           SizedBox(height: 16),
                           
                           ClipRRect(
                             borderRadius: BorderRadius.circular(4),
                             child: Container(
                               height: 8,
                               width: double.infinity,
                               child: LayoutBuilder(
                                 builder: (context, constraints) {
                                   final double rawProgress = (monthlyLimit > 0) ? (totalExpenses / monthlyLimit) : 0.0;
                                   final double progress = rawProgress.clamp(0.0, 1.0);
                                   final bool isOverLimit = rawProgress > 1.0;

                                   return Stack(
                                     children: [
                                       Container(color: Colors.grey.withOpacity(0.2)), 
                                       FractionallySizedBox(
                                         widthFactor: progress,
                                         child: Container(
                                           decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isOverLimit 
                                                  ? [Color(0xFFFF512F), Color(0xFFDD2476)] 
                                                  : [Color(0xFFEC4899), Color(0xFF8B5CF6)], 
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
                           SizedBox(height: 12),
                           Builder(
                             builder: (context) {
                               final bool isOverLimit = totalExpenses > monthlyLimit;
                               final double overage = (totalExpenses - monthlyLimit).abs();
                               
                               return Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Text(
                                     "₹${totalExpenses.toStringAsFixed(0)} spent out of ₹${monthlyLimit.toStringAsFixed(0)}",
                                     style: GoogleFonts.plusJakartaSans(
                                       fontSize: 12,
                                       fontWeight: FontWeight.w600,
                                       color: CoreTheme.deepInk.withOpacity(0.8),
                                     ),
                                   ),
                                   Text(
                                     isOverLimit 
                                        ? "Overspent: ₹${overage.toStringAsFixed(0)}" 
                                        : "₹${remainingAmount.toStringAsFixed(0)} left",
                                     style: GoogleFonts.plusJakartaSans(
                                       fontSize: 12,
                                       fontWeight: FontWeight.w700,
                                       color: isOverLimit ? Colors.redAccent : Color(0xFF8B5CF6),
                                     ),
                                   ),
                                 ],
                               );
                             }
                           ),
                           SizedBox(height: 16),
                           if (daysLeft > 0 && remainingAmount > 0)
                             Container(
                               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.6),
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: Row(
                                 children: [
                                   Icon(Icons.insights_rounded, color: Color(0xFFEC4899), size: 18),
                                   SizedBox(width: 12),
                                   Expanded(
                                     child: Text(
                                       "Try to stay under ₹${dailyRequired.toStringAsFixed(0)} per day to meet your goal.",
                                       style: GoogleFonts.plusJakartaSans(
                                         fontSize: 12,
                                         fontWeight: FontWeight.w500,
                                         color: CoreTheme.deepInk.withOpacity(0.8),
                                       ),
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

                SliverToBoxAdapter(child: SizedBox(height: 20)),

                


                
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
                                  fontWeight: FontWeight.w600, 
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
                         SizedBox(height: 16), 
                         
                          
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
                                SizedBox(width: 12), 
                                Expanded(
                                  child: Container(
                                    height: 1.5, 
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6).withOpacity(0.5), 
                                          Color(0xFFD946EF).withOpacity(0.5), 
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12), 
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
                            padding: EdgeInsets.only(bottom: 20), 
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
        return Icons.flight_takeoff_outlined; 
      case 'food/cafe':
      case 'food':
      case 'cafe':
        return Icons.local_cafe_outlined; 
      case 'social':
        return Icons.people_outline_rounded; 
      case 'work':
        return Icons.work_outline_rounded; 
      case 'shopping':
        return Icons.shopping_bag_outlined; 
      case 'home':
        return Icons.home_outlined; 
      case 'impulsive':
        return Icons.bolt_rounded; 
      default:
        return Icons.receipt_long_outlined; 
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
                radius: 16, 
                backgroundColor: Colors.grey.withOpacity(0.08), 
                child: Icon(
                  getIcon(entry.context),
                  color: Colors.black.withOpacity(0.7),
                  size: 18, 
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
                    SizedBox(height: 6), 
                      Text(
                        
                        () {
                          final time = DateFormat('h:mm a').format(entry.timestamp);
                          final mood = entry.mood.isEmpty ? "     " : entry.mood; 
                          final context = entry.context.isEmpty ? "     " : entry.context; 
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
                  color: Color(0xFF1A1A1A), 
                ),
              ),
            ],
          ),
        ), 
        SizedBox(height: 20), 
      ],
    );
  }
}



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
    
    final appearance = SettingsService().appearanceMode.value;
    final isSoft = appearance == AppearanceMode.soft;

    return Container(
      padding: EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: isSoft ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(isSoft ? 24 : 8),
        border: Border.all(
          
          color: iconColor.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          
          BoxShadow(
            color: iconColor.withOpacity(0.05),
            blurRadius: 30.0, 
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              icon,
              size: 20, 
              color: iconColor.withOpacity(0.9), 
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, 
                  fontWeight: FontWeight.w300, 
                  color: Color(0xFF1A1A1A).withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 4),
              
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, 
                  fontWeight: FontWeight.w700, 
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans( 
                   fontSize: 10,
                   color: Color(0xFF1A1A1A).withOpacity(0.5),
                   fontWeight: FontWeight.w300, 
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
