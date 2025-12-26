import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/expressive_widgets.dart';
import '../data/data_service.dart';
import '../widgets/core_drawer.dart';
import 'dart:ui' as ui;

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  bool _isLoading = false;

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get Data
      final jsonString = await DataService().repository.exportJson();
      
      // 2. Write to Temp File
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'savora_backup_$dateStr.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // 3. Share
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Savora Data Backup',
        text: 'Here is my Savora data backup.',
      );

    } catch (e) {
      _showError("Export failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFFFDFCFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Overwrite Data?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          "This will completely replace your current app data with the backup file. This action cannot be undone.",
          style: GoogleFonts.plusJakartaSans(color: Color(0xFF1A1A1A).withOpacity(0.8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text("Overwrite", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

        // 2. Import
        await DataService().repository.importJson(jsonString);
        
        // 3. Success
        _showSuccess("Data restored successfully!");
      }
    } catch (e) {
      _showError("Import failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFCFE),
      drawer: CoreDrawer(),
      body: Stack(
        children: [
          // 1. ATMOSPHERE
          Positioned(top: -100, left: -50, child: _GlowOrb(color: Color(0xFFE3D5FF), size: 400)),
          Positioned(bottom: -50, right: -50, child: _GlowOrb(color: Color(0xFFCBF3F0), size: 350)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.white.withOpacity(0.2)),
            ),
          ),

          // 2. CONTENT
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      Builder(builder: (c) => IconButton(
                        icon: Icon(Icons.menu_rounded, color: Color(0xFF1A1A1A)),
                        onPressed: () => Scaffold.of(c).openDrawer(),
                      )),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Data Management",
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      ),
                      SizedBox(width: 48), // Balance Icon
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // EXPORT CARD
                        _BackupCard(
                          title: "Backup Data",
                          description: "Export all your entries and intents to a JSON file. Keep it safe.",
                          icon: Icons.upload_file_rounded,
                          color: Color(0xFF8B5CF6),
                          buttonText: "Export Backup",
                          onTap: _exportData,
                          isLoading: _isLoading,
                        ),
                        
                        SizedBox(height: 24),

                        // IMPORT CARD
                        _BackupCard(
                          title: "Restore Data",
                          description: "Import a previously exported backup file. This will overwrite current data.",
                          icon: Icons.download_rounded,
                          color: Color(0xFF10B981),
                          buttonText: "Import Backup",
                          onTap: _importData,
                          isLoading: _isLoading,
                          isDestructive: false, 
                        ),

                        SizedBox(height: 48),
                        
                        // FOOTER INFO CARD
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip_rounded, size: 20, color: Colors.black45),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Your data is stored locally on this device. Backups are the only way to move data between devices.",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    height: 1.4,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String buttonText;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDestructive;

  const _BackupCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.buttonText,
    required this.onTap,
    required this.isLoading,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7), // Increased opacity for premium feel
        borderRadius: BorderRadius.circular(32), // Softer corners
        border: Border.all(color: Colors.white, width: 1.5), // Prismatic Border
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 24, offset: Offset(0, 12)),
          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 0, spreadRadius: 0, offset: Offset(0, 0)), // Inner light
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1), // Subtle icon border
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          SizedBox(height: 20),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Color(0xFF1A1A1A).withOpacity(0.6), height: 1.5),
            ),
          ),
          SizedBox(height: 28),
          UnifiedProButton(
            text: buttonText,
            onTap: isLoading ? () {} : onTap,
            gradientColors: [color, color.withOpacity(0.8)],
            isWide: true,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.5)));
  }
}
