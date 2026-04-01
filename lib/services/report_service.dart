import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io' as io;
import '../data/models/reflection_entry.dart';
import '../data/settings_service.dart';

class ReportService {
  Future<void> _generateAndShare(List<ReflectionEntry> entries, String userName, double monthlyLimit, String? profileImagePath) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    
    final fontRegular = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold(); 
    final fontLight = await PdfGoogleFonts.outfitLight(); 
    final iconFont = await PdfGoogleFonts.materialIcons();

    
    pw.ImageProvider? profileImage;
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      if (profileImagePath.startsWith('http')) {
        profileImage = await networkImage(profileImagePath);
      } else {
        final imageBytes = await io.File(profileImagePath).readAsBytes();
        profileImage = pw.MemoryImage(imageBytes);
      }
    }

    
    final currentMonth = DateTime(now.year, now.month);
    final monthEntries = entries.where((e) => 
      e.timestamp.year == currentMonth.year && 
      e.timestamp.month == currentMonth.month
    ).toList();

    double totalSpent = 0;
    for (var e in monthEntries) {
      if (e.amount < 0) totalSpent += e.amount.abs();
    }

    
    int afternoonCount = monthEntries.where((e) => e.timestamp.hour >= 16).length;
    bool highVelocityAfternoon = monthEntries.isNotEmpty && (afternoonCount / monthEntries.length > 0.5);
    
    final moodCounts = <String, int>{};
    final contextCounts = <String, int>{};
    for (var e in monthEntries) {
      moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
      contextCounts[e.context] = (contextCounts[e.context] ?? 0) + 1;
    }
    String topMood = moodCounts.isNotEmpty 
        ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key 
        : "Balanced";
    String topCategory = contextCounts.isNotEmpty 
        ? contextCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key 
        : "General";

    final tone = SettingsService().insightTone.value;
    String velocityText;
    String contextText;

    if (tone == 'Analytical') {
       velocityText = highVelocityAfternoon 
        ? "Data indicates a spending surge post-16:00." 
        : "Expenditure distribution remains uniform across standard hours.";
       contextText = "Primary correlation detected: '$topMood' state within '$topCategory' sector.";
    } else if (tone == 'Neutral') {
       velocityText = highVelocityAfternoon 
        ? "Spending velocity increased after 4 PM." 
        : "Spending was distributed evenly throughout the day.";
       contextText = "Most entries were logged as '$topMood' in '$topCategory'.";
    } else {
       velocityText = highVelocityAfternoon 
        ? "You tend to spend more in the evenings—perhaps it's time to unwind?" 
        : "Great job maintaining a balanced flow throughout the day!";
       contextText = "It seems you feel '$topMood' most often when spending on '$topCategory'.";
    }

    
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: pw.EdgeInsets.zero, 
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            icons: iconFont,
          ),
          buildBackground: (context) {
            return pw.Stack(
              children: [
                
                pw.Align(
                  alignment: pw.Alignment.topCenter,
                  child: pw.Container(
                    height: 15,
                    width: double.infinity, 
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [PdfColor.fromInt(0xFFEC4899), PdfColor.fromInt(0xFF8B5CF6)],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        ),
        
        
        footer: (context) => pw.Container(
          padding: pw.EdgeInsets.only(bottom: 20),
          width: double.infinity, 
          child: pw.Center( 
            child: pw.Text(
              "Crafted by Anand Choubey",
              style: pw.TextStyle(
                font: fontLight, 
                fontSize: 9, 
                letterSpacing: 1.2, 
                color: PdfColor.fromInt(0xFF9C27B0), 
              ),
            ),
          ),
        ),

        build: (pw.Context context) {
          return [
            
            pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(40, 60, 40, 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   
                   pw.Row(
                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       pw.Column(
                         crossAxisAlignment: pw.CrossAxisAlignment.start,
                         children: [
                           pw.Text(
                             "FINANCIAL REPORT",
                             style: pw.TextStyle(
                               font: fontBold, 
                               fontSize: 24, 
                               letterSpacing: 3.0,
                               color: PdfColor.fromInt(0xFF1F2937),
                             ),
                           ),
                           pw.SizedBox(height: 8),
                            pw.Text(
                             "GENERATED ON ${dateFormat.format(now).toUpperCase()}  |  FOR ${userName.toUpperCase()}",
                             style: pw.TextStyle(
                               font: fontRegular, 
                               fontSize: 8, 
                               letterSpacing: 1.5, 
                               color: PdfColors.grey500
                             ),
                           ),
                         ],
                       ),
                       
                       pw.Container(
                         height: 48, 
                         width: 48,
                         decoration: pw.BoxDecoration(
                           shape: pw.BoxShape.circle,
                           border: pw.Border.all(color: PdfColors.grey200, width: 1.5), 
                           image: profileImage != null ? pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover) : null,
                         ),
                         child: profileImage == null ? pw.Center(
                           child: pw.Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                              style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColor.fromInt(0xFF8B5CF6))
                           )
                         ) : null,
                       ),
                     ],
                   ),
                   
                   pw.SizedBox(height: 40),

                   
                   pw.Row(
                     children: [
                       _buildMetric("TOTAL SPENT", "INR ${totalSpent.toStringAsFixed(0)}", fontBold, color: PdfColor.fromInt(0xFF8B5CF6)),
                       pw.SizedBox(width: 40),
                       _buildMetric("MONTHLY GOAL", "INR ${monthlyLimit.toStringAsFixed(0)}", fontBold),
                       pw.SizedBox(width: 40),
                       _buildSimpleStatus(totalSpent, monthlyLimit, fontBold),
                     ],
                   ),

                   pw.SizedBox(height: 40),

                   
                   pw.Container(
                     padding: pw.EdgeInsets.only(left: 12),
                     decoration: pw.BoxDecoration(
                       border: pw.Border(left: pw.BorderSide(color: PdfColor.fromInt(0xFF8B5CF6), width: 2)),
                     ),
                     child: pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                         pw.Text("BEHAVIORAL INSIGHT", style: pw.TextStyle(font: fontBold, fontSize: 8, letterSpacing: 1.5, color: PdfColors.grey500)),
                         pw.SizedBox(height: 6),
                         pw.Text("$velocityText\n$contextText", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800, lineSpacing: 4)),
                       ],
                     ),
                   ),

                   pw.SizedBox(height: 40),
                   
                   pw.Text("TRANSACTION HISTORY", style: pw.TextStyle(font: fontBold, fontSize: 10, letterSpacing: 1.5, color: PdfColors.grey400)),
                   pw.SizedBox(height: 16),

                   
                   ...monthEntries.map((e) {
                     return pw.Container(
                       margin: pw.EdgeInsets.only(bottom: 12),
                       padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: pw.BoxDecoration(
                         color: PdfColor.fromInt(0xFFF9FAFB), 
                         borderRadius: pw.BorderRadius.circular(12),
                         border: pw.Border.all(color: PdfColor.fromInt(0xFFE5E7EB), width: 0.5), 
                         
                       ),
                       child: pw.Stack(
                         children: [
                            
                            pw.Positioned(
                              top: 0, left: 0, right: 0,
                              child: pw.Container(height: 1, color: PdfColors.white)
                            ),
                            
                            pw.Row(
                             crossAxisAlignment: pw.CrossAxisAlignment.center,
                             children: [
                               
                               pw.Container(
                                 width: 80,
                                 child: pw.Column(
                                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                                   children: [
                                     pw.Row(
                                       children: [
                                         _getIconForContext(e.context),
                                         pw.SizedBox(width: 6),
                                         pw.Text(e.mood.isEmpty ? "Neutral" : e.mood, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromInt(0xFF8B5CF6))), 
                                       ]
                                     ),
                                     pw.SizedBox(height: 4),
                                     pw.Text(e.context, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                                   ]
                                 )
                               ),
                               
                               
                               pw.Expanded(
                                 child: pw.Column(
                                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                                   children: [
                                     pw.Text(e.note.isEmpty ? "-" : e.note, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey900)), 
                                     pw.SizedBox(height: 4),
                                     pw.Text(
                                       "${dateFormat.format(e.timestamp)}  •  ${timeFormat.format(e.timestamp)}", 
                                       style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700) 
                                     ),
                                   ]
                                 )
                               ),

                               
                               pw.Text(
                                 "INR ${e.amount.abs().toStringAsFixed(0)}", 
                                 style: pw.TextStyle(
                                   font: fontBold, 
                                   fontSize: 15, 
                                   color: PdfColors.black, 
                                 )
                               ),
                             ]
                           ),
                         ]
                       )
                     );
                   }).toList(),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Savora_Report_${now.day}_${now.hour}${now.minute}${now.second}.pdf');
  }

  
  
  pw.Widget _buildMetric(String label, String value, pw.Font fontBold, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 8, letterSpacing: 1, color: PdfColors.grey400)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16, color: color ?? PdfColors.black)),
      ],
    );
  }

  pw.Widget _buildSimpleStatus(double spent, double limit, pw.Font fontBold) {
     final bool onTrack = spent <= limit;
     final color = onTrack ? PdfColor.fromInt(0xFF10B981) : PdfColor.fromInt(0xFFEF4444);
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("STATUS", style: pw.TextStyle(font: fontBold, fontSize: 8, letterSpacing: 1, color: PdfColors.grey400)),
        pw.SizedBox(height: 4),
        pw.Text(onTrack ? "ON TRACK" : "OVER LIMIT", style: pw.TextStyle(font: fontBold, fontSize: 12, color: color, letterSpacing: 1)),
      ],
    );
  }

  
  Future<void> generateAndShare(List<ReflectionEntry> entries, String userName, double monthlyLimit, String? profileImagePath) async {
      await _generateAndShare(entries, userName, monthlyLimit, profileImagePath);
  }

  pw.Widget _getIconForContext(String context) {
    int codePoint;
    switch(context) {
      case 'Home': codePoint = 0xe88a; break;
      case 'Work': codePoint = 0xe8f9; break;
      case 'Cafe': codePoint = 0xe541; break;
      case 'Social': codePoint = 0xe7fb; break; 
      case 'Travel': codePoint = 0xe539; break; 
      case 'Online': codePoint = 0xe80b; break; 
      default: codePoint = 0xe88a; 
    }
    return pw.Icon(pw.IconData(codePoint), color: PdfColor.fromInt(0xFF8B5CF6), size: 10); 
  }
}
