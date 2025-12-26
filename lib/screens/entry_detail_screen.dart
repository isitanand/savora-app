import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';
import '../theme/core_theme.dart';

class EntryDetailScreen extends StatelessWidget {
  final ReflectionEntry entry;

  EntryDetailScreen({super.key, required this.entry});

  Future<void> _deleteEntry(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Reflection?'),
        content: Text('This trace will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DataService().repository.deleteEntry(entry.id);
      if (context.mounted) {
        Navigator.pop(context, true); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        title: Text(
          "Visual Trace", 
          style: GoogleFonts.plusJakartaSans(
            color: Color(0xFF1A1A1A), 
            fontSize: 16, 
            fontWeight: FontWeight.w700
          )
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.05)),
              child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
            ),
            onPressed: () => _deleteEntry(context),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              SizedBox(height: 20),
              
              // 1. TRANSACTION PILL
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "TRANSACTION",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black38,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // 2. HERO AMOUNT (Black, huge)
              Text(
                "₹${entry.amount.abs().toStringAsFixed(0)}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -2,
                ),
              ),
              
              SizedBox(height: 8),
              
              // 3. DATE
              Text(
                DateFormat('MMMM d, yyyy • hh:mm a').format(entry.timestamp),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),

              SizedBox(height: 48),

              // 4. DATA CARD
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricItem(
                          _getIconForMood(entry.mood), 
                          entry.mood, 
                          "MOOD"
                        ),
                        _buildDivider(),
                        _buildMetricItem(
                          Icons.dashboard_rounded, 
                          "Home", // Hardcoded per image or logic
                          "CATEGORY"
                        ),
                        _buildDivider(),
                        _buildMetricItem(
                          Icons.wb_sunny_outlined, 
                          _getTimeOfDay(entry.timestamp), 
                          "PHASE"
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                     Container(height: 1, color: Colors.grey[100]),
                    SizedBox(height: 32),

                    // REFLECTION
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(width: 3, height: 12, color: Color(0xFFEC4899), margin: EdgeInsets.only(right: 8)),
                          Text(
                            "THE REFLECTION", 
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, 
                              fontWeight: FontWeight.w800, 
                              color: Colors.black38, 
                              letterSpacing: 1.5
                            )
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                         color: Colors.grey[50],
                         borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        entry.note.isNotEmpty ? entry.note : "No whispered thoughts for this moment.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.5,
                          color: entry.note.isNotEmpty ? Color(0xFF1A1A1A) : Colors.black45,
                          fontStyle: entry.note.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Color(0xFF8B5CF6).withOpacity(0.8)),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black26),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey[200],
    );
  }

  String _getTimeOfDay(DateTime time) {
    if (time.hour < 12) return "Morning";
    if (time.hour < 17) return "Afternoon";
    return "Evening";
  }

  IconData _getIconForMood(String mood) {
     // Simplified icon mapping
     return Icons.face_rounded; 
  }
}
