import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptics
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../theme/core_theme.dart';
import '../data/settings_service.dart'; // Settings Service
import 'dart:ui' as ui;
import '../theme/core_theme.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;

  PremiumCard({
    super.key, 
    required this.child, 
    this.onTap,
    this.padding = CoreTheme.cardPadding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? CoreTheme.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CoreTheme.premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  GradientButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
             Color(0xFFEC4899), // Pink top
             Color(0xFF8B5CF6), // Purple bottom
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // MANDATE: Deep Purple Spread
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.5), // Increased opacity for depth
            blurRadius: 16.0,
            offset: Offset(0, 6),
          ),
          // MANDATE: Inner White Lip Simulation (via top white shadow/border effect)
          BoxShadow(
             color: Colors.white.withOpacity(0.25),
             blurRadius: 1.0, 
             offset: Offset(0, -1), // Top lip
             spreadRadius: 0.5,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(1.0), // Mandate: 100% opacity
                    fontWeight: FontWeight.w800, // Mandate: w800
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoodAvatar extends StatelessWidget {
  final String mood;
  MoodAvatar({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    // Generate a consistent color based on string hash for visual variety
    final safeMood = mood.isEmpty ? '?' : mood;
    final color = _getColor(safeMood);
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          mood.isNotEmpty ? mood[0].toUpperCase() : '?',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Color _getColor(String s) {
    final colors = [
      CoreTheme.primaryAccent,
      CoreTheme.secondaryAccent,
      Colors.blueAccent,
      Colors.teal,
      Colors.orange,
    ];
    return colors[s.hashCode.abs() % colors.length];
  }
}

class InsightGraph extends StatefulWidget {
  final List<double> data;
  final Color color;
  final double? targetLimit;
  final int? todayIndex;
  final bool isMonthly;

  InsightGraph({
    super.key, 
    required this.data,
    this.color = CoreTheme.secondaryAccent,
    this.targetLimit,
    this.todayIndex,
    this.isMonthly = true,
  });

  @override
  State<InsightGraph> createState() => _InsightGraphState();
}

class _InsightGraphState extends State<InsightGraph> {
  int? _tappedIndex;
  Offset? _tapPosition;

  void _handleTap(TapUpDetails details, double width) {
    // Logic matches CustomPainter: leftMargin = 30
    const double leftMargin = 30.0;
    final double drawingWidth = width - leftMargin;
    
    if (details.localPosition.dx < leftMargin) return;

    // Fixed 30 days for Monthly
    final int totalPoints = widget.isMonthly ? 30 : (widget.data.length > 0 ? widget.data.length : 1);
    final double widthStep = drawingWidth / totalPoints;

    int index = ((details.localPosition.dx - leftMargin) / widthStep).round();
    
    // Clamp
    if (index < 0) index = 0;
    if (index >= totalPoints) index = totalPoints - 1;
    
    // Mandate: "Stick to current date" if tapping future
    // Strict enforcement: Snap to today if index > today
    int safeToday = widget.todayIndex ?? (DateTime.now().day - 1);
    
    if (index > safeToday) {
      index = safeToday;
    }
    
    setState(() {
      _tappedIndex = index;
      _tapPosition = details.localPosition;
    });

    // Auto-hide after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _tappedIndex == index) { // Check if still same interaction
        setState(() { _tappedIndex = null; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints.maxWidth),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _VelocityChartPainter(
                    data: widget.data, 
                    color: widget.color,
                    targetLimit: widget.targetLimit,
                    todayIndex: widget.todayIndex,
                    isMonthly: widget.isMonthly,
                    highlightIndex: _tappedIndex, // Pass to painter for glow effect
                  ),
                ),
              ),
              // Premium Glass Tooltip
              if (_tappedIndex != null)
                _buildTooltip(constraints.maxWidth),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTooltip(double width) {
    // Calculate Position
    const double leftMargin = 30.0;
    final double drawingWidth = width - leftMargin;
    final double widthStep = drawingWidth / 30; // Assuming monthly
    final double x = leftMargin + (_tappedIndex! * widthStep);
    
    // Calculate Value for Display
    double value = 0.0;
    // Cumulative Sum logic
    // We need to sum up to _tappedIndex
    if (widget.data.isNotEmpty) {
      int limit = _tappedIndex! < widget.data.length ? _tappedIndex! : widget.data.length - 1;
      // If tapped index is active (has data), sum it.
      // If tapped index is future (no data yet), we technically show last known sum or 0? 
      // Let's show cumulative up to that day (which is constant if no new spending).
      
      // Wait, if I tap Day 30 and today is Day 24, should I show Day 24's total? 
      // Yes, cumulative graph is flat.
      
      // Safe clamp
      int loopLimit = _tappedIndex! >= widget.data.length ? widget.data.length - 1 : _tappedIndex!;
      for (int i=0; i<=loopLimit; i++) value += widget.data[i];
    }

    // Dynamic Left Position (centered on node)
    // Ensure doesn't overflow screen edges
    double leftPos = x - 60; // Center 120px wide tooltip
    if (leftPos < 0) leftPos = 10;
    if (leftPos + 120 > width) leftPos = width - 130;

    return Positioned(
      top: 10, // Fixed at top for clarity, or follow Y? User asked for "Clear Position". Top is clear.
      left: leftPos,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // Glass
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B5CF6).withOpacity(0.2), // Purple shadow
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Day ${_tappedIndex! + 1}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CoreTheme.softGraphite.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 2),
            Text(
              "₹${value.toStringAsFixed(0)}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEC4899), // Pink Text
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VelocityChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double? targetLimit;
  final int? todayIndex;
  final bool isMonthly;
  final int? highlightIndex;
  
  _VelocityChartPainter({
    required this.data, 
    required this.color,
    this.targetLimit,
    this.todayIndex,
    this.isMonthly = true,
    this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Margins for Axis Labels
    const double bottomMargin = 20.0;
    const double leftMargin = 30.0;
    
    final drawingRect = Rect.fromLTWH(
      leftMargin, 
      0, 
      size.width - leftMargin, 
      size.height - bottomMargin
    );

    // Draw Axis Labels first
    _drawAxisLabels(canvas, size, leftMargin, bottomMargin);

    // Mandate: Strict Scaling (maxY = targetLimit as set by user)
    // If targetLimit is null/0, default to 4000 or max data to avoid crash
    final double maxVal = (targetLimit != null && targetLimit! > 0) ? targetLimit! : 4000.0;
    
    // CUMULATIVE LOGIC: Convert data to cumulative sums
    final List<double> cumulativeData = [];
    double runningTotal = 0.0;
    for (int i = 0; i < data.length; i++) {
      runningTotal += data[i];
      cumulativeData.add(runningTotal);
    }
    
    // TEMPORAL FIX: Show entire month context starting from Day 1
    const int startIndex = 0; 
    
    // TEMPORAL FIX: Clip at current day (todayIndex)
    final int endIndex = todayIndex != null && todayIndex! < cumulativeData.length ? todayIndex! : cumulativeData.length - 1;
    
    final widthStep = drawingRect.width / (isMonthly ? 30 : cumulativeData.length - 1);

    // 1. Target Line Removed per user request


    // 2. Draw Today Indicator
    if (todayIndex != null) {
      final todayX = drawingRect.left + (todayIndex! * widthStep);
      final todayPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(todayX, drawingRect.top), Offset(todayX, drawingRect.bottom), todayPaint);
    }

    // 3. Draw Cumulative Line - VIBRANT 3PX WITH NEON GLOW
    final actualPath = Path();
    
    for (int i = startIndex; i <= endIndex; i++) {
      final x = drawingRect.left + (i * widthStep);
      // Ensure we don't divide by zero or negative
      final safeMaxVal = maxVal <= 0 ? 1.0 : maxVal;
      final val = cumulativeData[i];
      final y = drawingRect.bottom - (val / safeMaxVal * drawingRect.height);
      
      if (i == startIndex) {
        actualPath.moveTo(x, y);
      } else {
        actualPath.lineTo(x, y);
      }
    }

    // Mandate: Solid Vibrant Pink Line (No Blur)
    final linePaint = Paint()
      ..color = Color(0xFFEC4899) // Vibrant Pink
      ..strokeWidth = 3.0 // Mandate: 3px thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(actualPath, linePaint);
    
    // 4. Draw Glowing Node at Current Day (End of Line)
    if (endIndex >= startIndex && endIndex < cumulativeData.length) {
      final lastX = drawingRect.left + (endIndex * widthStep);
      final lastVal = cumulativeData[endIndex];
      final lastY = drawingRect.bottom - (lastVal / (maxVal <= 0 ? 1.0 : maxVal) * drawingRect.height);
      
      // Glow Shadow
      canvas.drawCircle(
        Offset(lastX, lastY),
        8.0, 
        Paint()..color = Color(0xFFEC4899).withOpacity(0.4)..maskFilter = MaskFilter.blur(BlurStyle.normal, 4)
      );
      
      // White Center
      canvas.drawCircle(
        Offset(lastX, lastY), 
        4.0, 
        Paint()..color = Colors.white
      );
      
      // Ring
      canvas.drawCircle(
        Offset(lastX, lastY), 
        4.0, 
        Paint()..color = Color(0xFFEC4899)..style = PaintingStyle.stroke..strokeWidth = 2.0
      );
    }

    // 5. Draw INTERACTIVE Highlight Node
    if (highlightIndex != null) {
      // Logic: If tapped index is active data range, snap to node.
      // If tapped index is future (no data), snap to end of line or don't show node?
      // User tapped there, let's show node at closest point on line.
      
      int effectiveIdx = highlightIndex!;
      if (effectiveIdx > endIndex) effectiveIdx = endIndex; 
      if (effectiveIdx < startIndex) effectiveIdx = startIndex;

      if (effectiveIdx < cumulativeData.length) {
         final highlightX = drawingRect.left + (effectiveIdx * widthStep); 
         
         final highlightVal = cumulativeData[effectiveIdx];
         final safeMaxVal = maxVal <= 0 ? 1.0 : maxVal;
         final highlightY = drawingRect.bottom - (highlightVal / safeMaxVal * drawingRect.height);

         // Stronger Interaction Glow
         canvas.drawCircle(
           Offset(highlightX, highlightY),
           12.0, 
           Paint()..color = Colors.white.withOpacity(0.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, 8)
         );
         
         canvas.drawCircle(
           Offset(highlightX, highlightY), 
           6.0, 
           Paint()..color = Color(0xFFEC4899)
         );
         
         canvas.drawCircle(
           Offset(highlightX, highlightY), 
           3.0, 
           Paint()..color = Colors.white
         );
      }
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double leftMargin, double bottomMargin) {
     final textStyle = GoogleFonts.plusJakartaSans(
       fontSize: 10,
       color: Color(0xFF2A2A2A).withOpacity(0.5), // Mandate: 0.5 opacity per user request (was 0.4/1.0)
       fontWeight: FontWeight.w600, 
     );

     // X-Axis (Days: 1, 5, 10, 15, 20, 25, 30)
     final xIntervals = [1, 5, 10, 15, 20, 25, 30];
     final drawingWidth = size.width - leftMargin;
     final widthStep = drawingWidth / 30;

     for (var day in xIntervals) {
       final x = leftMargin + ((day - 1) * widthStep); // data index is day-1
       final textSpan = TextSpan(text: '$day', style: textStyle);
       final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
       textPainter.layout();
       textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - 15));
     }

     // Y-Axis (Strict Labels: 0, Limit/2, Limit) - MANDATE: Ensure top label is visible
     final double maxVal = targetLimit ?? (data.isEmpty ? 100 : data.reduce((a, b) => a > b ? a : b));
     final yValues = [0, maxVal / 2, maxVal];
     final drawingHeight = size.height - bottomMargin - 20; // MANDATE: 20px top padding for "4k" visibility
    
    for (var val in yValues) {
      final y = 20 + (drawingHeight - (val / maxVal * drawingHeight)); // MANDATE: Start 20px from top
      
      final label = val >= 1000 ? '${(val/1000).toStringAsFixed(1)}k' : val.toStringAsFixed(0);
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      // Mandate: Increased padding to prevent cutoff
      textPainter.paint(canvas, Offset(2, y - (textPainter.height / 2))); // Added 2px left padding
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> dashArray) {
    final ui.PathMetrics metrics = path.computeMetrics();
    for (ui.PathMetric metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray[draw ? 0 : 1];
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VelocityChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.highlightIndex != highlightIndex ||
           oldDelegate.todayIndex != todayIndex;
  }
}

class WeeklyBarChart extends StatefulWidget {
  final List<double> thisWeek;
  final List<double> lastWeek;

  WeeklyBarChart({
    super.key,
    required this.thisWeek,
    required this.lastWeek,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int? _tappedIndex;

  void _handleTap(TapUpDetails details, double width) {
    const double leftMargin = 30.0;
    // const double bottomMargin = 20.0; // Unused
    
    // Tap area check
    if (details.localPosition.dx < leftMargin) return;

    final drawingWidth = width - leftMargin;
    
    // Geometry matching Painter
    double barWidth = 12.0; 
    double internalGap = 4.0;
    double singleGroupWidth = (barWidth * 2) + internalGap;
    
    // Calculate gap used in painter
    double groupGap = (drawingWidth - (singleGroupWidth * 7)) / 6;
    if (groupGap < 0) groupGap = 0;

    // Determine Index
    // x = i * (singleGroupWidth + groupGap)
    // i = x / step
    final double step = singleGroupWidth + groupGap;
    final double relativeX = details.localPosition.dx - leftMargin;
    
    // Add half step tolerance to the left/right
    int index = (relativeX / step).floor();
    
    // Clamp/Validation
    if (index >= 0 && index < 7) {
       setState(() {
         _tappedIndex = index;
       });

       // Auto-hide
       Future.delayed(Duration(seconds: 3), () {
         if (mounted) setState(() { _tappedIndex = null; });
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints.maxWidth),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeeklyBarPainter(
                    thisWeek: widget.thisWeek, 
                    lastWeek: widget.lastWeek,
                    highlightIndex: _tappedIndex,
                  ),
                ),
              ),
              if (_tappedIndex != null)
                _buildTooltip(constraints.maxWidth),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTooltip(double width) {
    // 1. Calculate X Position exactly like Painter
    const double leftMargin = 30.0;
    double barWidth = 12.0; 
    double internalGap = 4.0;
    double singleGroupWidth = (barWidth * 2) + internalGap;
    double groupGap = ((width - leftMargin) - (singleGroupWidth * 7)) / 6;
    if (groupGap < 0) groupGap = 0;
    
    final double groupX = leftMargin + (_tappedIndex! * (singleGroupWidth + groupGap));
    // Center over the RIGHT bar (This Week)
    final double targetX = groupX + barWidth + internalGap + (barWidth / 2);
    
    // 2. Data
    final double amount = widget.thisWeek[_tappedIndex!];
    final double lastAmount = widget.lastWeek[_tappedIndex!];
    final String dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][_tappedIndex!];
    
    // 3. Tooltip Positioning
    double tooltipWidth = 140;
    double leftPos = targetX - (tooltipWidth / 2);
    // Boundary checks
    if (leftPos < 0) leftPos = 10;
    if (leftPos + tooltipWidth > width) leftPos = width - tooltipWidth - 10;

    return Positioned(
      top: -10, // Higher up
      left: leftPos,
      child: Container(
        width: tooltipWidth,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFEC4899).withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dayName, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
            SizedBox(height: 2),
            Text("₹${amount.toStringAsFixed(0)}", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEC4899))),
            if (lastAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text("vs ₹${lastAmount.toStringAsFixed(0)}", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.black38)),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  final List<double> thisWeek;
  final List<double> lastWeek;
  final int? highlightIndex;

  _WeeklyBarPainter({required this.thisWeek, required this.lastWeek, this.highlightIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // Mandate: Add Axes for Weekly Chart
    const double bottomMargin = 20.0;
    const double leftMargin = 30.0;
    
    final drawingRect = Rect.fromLTWH(
      leftMargin, 
      0, 
      size.width - leftMargin, 
      size.height - bottomMargin
    );

    // Mandate: Dynamic Spacing to "Spread thoroughly"
    double barWidth = 12.0; 
    double internalGap = 4.0; // Gap between LastWeek and ThisWeek bars within a group
    
    // Calculate total width of a single group (Bar + Bar + Gap)
    double singleGroupWidth = (barWidth * 2) + internalGap;
    
    // Calculate available width for distribution
    // We want 7 groups spread across the width
    final double availableWidth = drawingRect.width;
    
    // Ensure we don't divide by zero if width is weirdly small
    double groupGap = (availableWidth - (singleGroupWidth * 7)) / 6;
    if (groupGap < 0) groupGap = 0; // Fallback
    
    // Start exactly at left edge to use full width
    final double startX = drawingRect.left;

    _drawAxes(canvas, size, leftMargin, bottomMargin, startX, barWidth, groupGap, internalGap);

    // Max Value Logic for scaling
    final allValues = [...thisWeek, ...lastWeek];
    final double maxVal = allValues.isEmpty || allValues.every((e) => e == 0) ? 100 : allValues.reduce((a, b) => a > b ? a : b) * 1.2;
    
    for (int i = 0; i < 7; i++) {
        final double x = startX + i * (singleGroupWidth + groupGap);
        
        // HIGHLIGHT GLOW
        if (highlightIndex != null && i == highlightIndex) {
           // Draw subtle vertical highlight column
           canvas.drawRRect(
             RRect.fromRectAndRadius(
               Rect.fromLTWH(x - 4, 0, singleGroupWidth + 8, drawingRect.bottom + 10),
               Radius.circular(8)
             ),
             Paint()..color = Color(0xFFEC4899).withOpacity(0.05)
           );
        }

        // Last Week Bar (Violet Comparison) - LEFT
        final double lastY = drawingRect.bottom - (lastWeek[i] / maxVal * drawingRect.height);
        canvas.drawRRect(
          RRect.fromLTRBR(x, lastY, x + barWidth, drawingRect.bottom, Radius.circular(4)),
          Paint()..color = Color(0xFF8B5CF6).withOpacity(0.5), // Violet Comparison
        );

        // This Week Bar (Pink Primary) - RIGHT
        final double thisY = drawingRect.bottom - (thisWeek[i] / maxVal * drawingRect.height);
        canvas.drawRRect(
          RRect.fromLTRBR(x + barWidth + internalGap, thisY, x + barWidth + internalGap + barWidth, drawingRect.bottom, Radius.circular(4)),
          Paint()..color = Color(0xFFEC4899),
        );
    }
  }

  void _drawAxes(Canvas canvas, Size size, double leftMargin, double bottomMargin, double startX, double barWidth, double groupGap, double internalGap) {
      final textStyle = GoogleFonts.plusJakartaSans(
       fontSize: 10, 
       color: Color(0xFF2A2A2A).withOpacity(0.5), // Mandate: 0.5 opacity (Standardized)
       fontWeight: FontWeight.w600, // Mandate: w600 (Standardized)
     );

     // X-Axis: M T W T F S S
     final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
     final double singleGroupWidth = (barWidth * 2) + internalGap;
     
     for (int i = 0; i < days.length; i++) {
       final textSpan = TextSpan(text: days[i], style: textStyle);
       final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
       textPainter.layout();
       
       // Calculate X position to align EXACTLY under the Current Week Bar (Right bar in group)
       final double groupX = startX + i * (singleGroupWidth + groupGap);
       
       // Current Week Bar X start = groupX + barWidth + internalGap
       final double currentWeekBarCenter = groupX + barWidth + internalGap + (barWidth / 2);
       
       // Align center of text with center of Current Week Bar
       final x = currentWeekBarCenter - (textPainter.width / 2);
       
       textPainter.paint(canvas, Offset(x, size.height - 15));
     }

     // Y-Axis: 0, Mid, Max
    final allValues = [...thisWeek, ...lastWeek];
    final double maxVal = allValues.isEmpty || allValues.every((e) => e == 0) ? 100 : allValues.reduce((a, b) => a > b ? a : b);
     
     final yLabels = [0, maxVal / 2, maxVal];
     final drawingHeight = size.height - bottomMargin;
     
     for (var val in yLabels) {
        final y = drawingHeight - (val / (maxVal * 1.2) * drawingHeight);
        final label = val >= 1000 ? '${(val/1000).toStringAsFixed(1)}k' : val.toStringAsFixed(0);
        final textSpan = TextSpan(text: label, style: textStyle);
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(0, y - (textPainter.height / 2)));
     }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter oldDelegate) => 
    oldDelegate.thisWeek != thisWeek || 
    oldDelegate.lastWeek != lastWeek ||
    oldDelegate.highlightIndex != highlightIndex;

// End of existing file content or append at end
}

class UnifiedProButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final double? width;
  final bool isDestructive;
  final bool isWide; // Added as requested by user build error
  final bool isLoading;

  UnifiedProButton({
    super.key,
    required this.text,
    required this.onTap,
    this.gradientColors = const [Color(0xFFBB86FC), Color(0xFFCF6679)], // Default Lavender-Rose
    this.width,
    this.isDestructive = false,
    this.isWide = false,
    this.isLoading = false,
  });

  @override
  State<UnifiedProButton> createState() => _UnifiedProButtonState();
}

class _UnifiedProButtonState extends State<UnifiedProButton> {
  bool _isPressed = false;

  // Helper: Increase saturation by 30%
  Color _increaseSaturation(Color color, double factor) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withSaturation((hslColor.saturation * factor).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    // Mandate: Appearance Mode Logic
    return ValueListenableBuilder<AppearanceMode>(
      valueListenable: SettingsService().appearanceMode,
      builder: (context, mode, child) {
        final isSoft = mode == AppearanceMode.soft;
        
        // Mandate: +30% Saturation for Soft Mode
        final vibrantColors = isSoft
            ? widget.gradientColors.map((c) => _increaseSaturation(c, 1.3)).toList()
            : widget.gradientColors;
        
        // Effective Width
        final effectiveWidth = widget.isWide ? double.infinity : (widget.width ?? MediaQuery.of(context).size.width * 0.5);

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.lightImpact(); // Mandate: Feedback
            if (!widget.isLoading) widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: isSoft && _isPressed ? 0.97 : 1.0, // Mandate: Scale 0.97 for Soft
            duration: Duration(milliseconds: 150),
            child: AnimatedOpacity(
              opacity: !isSoft && _isPressed ? 0.8 : 1.0, // Mandate: Opacity shift for Sharp
              duration: Duration(milliseconds: 100),
              child: Container(
                width: effectiveWidth, // Mandate: Responsive Width
                height: 60,
                decoration: BoxDecoration(
                   borderRadius: isSoft 
                     ? BorderRadius.circular(100) // Mandate: StadiumBorder (Pill)
                     : BorderRadius.circular(12), // Mandate: 12px for Premium Sharp
                   boxShadow: isSoft 
                     ? [
                         // Mandate: Outer Drop Shadow (Deep Purple, 0.3 opacity, 12 blur, 4 offset)
                         BoxShadow(
                           color: Color(0xFF8B5CF6).withOpacity(0.3),
                           blurRadius: 12,
                           offset: Offset(0, 4),
                         ),
                         // Mandate: Inner Shadow simulation
                         BoxShadow(
                           color: Colors.white.withOpacity(0.5),
                           blurRadius: 0,
                           offset: Offset(0, -2), 
                           spreadRadius: 0,
                         )
                       ]
                     : [
                         // Mandate: Premium Tactile Sharp - Deep Violet Hard Shadow (No Border)
                         BoxShadow(
                           color: Color(0xFF4C1D95).withOpacity(0.4), // Deep Violet, 0.4 opacity
                           offset: Offset(0, 4), // Deeper offset for tactile feel
                           blurRadius: 0, // Sharp
                         )
                       ],
                    gradient: LinearGradient(
                      colors: isSoft 
                        ? [
                            Color(0xFF8B5CF6), // Violet
                            Color(0xFFEC4899), // Pink
                            Colors.white.withOpacity(0.8), // Soft White end
                          ]
                        : widget.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    // Mandate: No black border for Sharp - cleaner look
                    border: isSoft ? null : null, 
                ),
                child: ClipRRect(
                  borderRadius: isSoft 
                     ? BorderRadius.circular(100) 
                     : BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: isSoft ? 12.0 : 0.0, // Mandate: sigma 12 for Soft, 0 for Sharp
                      sigmaY: isSoft ? 12.0 : 0.0
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            vibrantColors.first.withValues(alpha: isSoft ? 0.65 : 0.95), // Mandate: 0.65 Soft (increased from 0.55)
                            vibrantColors.last.withValues(alpha: isSoft ? 0.65 : 0.95),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // SPECULAR SHINE OVERLAY (Soft Mode Only)
                          if (isSoft)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.0, -1.0),
                                    end: Alignment(1.0, 1.0),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.2), // Mandate: White 0.2
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.5], // 45-degree shine
                                  ),
                                ),
                              ),
                            ),
                          
                          // CONTENT (Perfectly Centered, No Icons)
                          Center(
                            child: Text(
                              widget.text,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, 
                                fontWeight: FontWeight.w800, // Mandate: w800 for maximum legibility
                                color: Colors.white.withOpacity(1.0), // Mandate: 1.0 opacity
                                letterSpacing: 1.2, // Mandate: 1.2
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
          ),
        );
      },
    );
  }
}
