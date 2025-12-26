import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/report_service.dart';
import '../theme/core_theme.dart';
import '../data/settings_service.dart';
import '../data/data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  // --- ACTIONS ---

  Future<void> _editName() async {
    final TextEditingController controller = TextEditingController(text: SettingsService().userName.value);
    await showDialog(
      context: context,
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: Offset(0, 20)),
                  BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 0, offset: Offset(0, -1), spreadRadius: 0), // White Lip Top
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Identity",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "How should we greet you?",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A).withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // 3D Tactile Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4)),
                        BoxShadow(color: Colors.white, blurRadius: 1, offset: Offset(0, -1), spreadRadius: 1), // Top Lip
                      ],
                    ),
                    child: TextField(
                      autofocus: true,
                      controller: controller,
                      cursorColor: Color(0xFF9C27B0),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                      decoration: InputDecoration(
                        hintText: "Your Name",
                        hintStyle: TextStyle(color: Colors.black26),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("Cancel", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.black45)),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final newName = controller.text.trim();
                            if (newName.isNotEmpty) {
                              SettingsService().setUserName(newName);
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF8B5CF6).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                                BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 0, offset: Offset(0, -2), spreadRadius: 0), // Button top lip
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "Confirm",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // 1. CROP IMAGE
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: Color(0xFF9C27B0),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
            IOSUiSettings(
              title: 'Crop Profile Picture',
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
            ),
          ],
        );

        if (croppedFile != null) {
          SettingsService().setProfileImage(croppedFile.path);
          setState(() {}); 
        }
      }
    } catch (e) {
      debugPrint("Image Picker Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not pick image")));
    }
  }

  Future<void> _exportData() async {
    try {
      final entries = await DataService().repository.getEntries();
      final userName = SettingsService().userName.value;
      final limit = SettingsService().monthlyLimit.value;
      final imagePath = SettingsService().profileImagePath.value;

      // SHOW PREMIUM LOADING DIALOG
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.2), // Darker tint for contrast
        builder: (context) {
          return Stack(
            children: [
               // 1. FULL SCREEN BLUR
               Positioned.fill(
                 child: BackdropFilter(
                   filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Strong blur
                   child: Container(color: Colors.transparent),
                 ),
               ),
               // 2. 3D GLASS CARD
               Center(
                 child: Material( // Essential for Text widget inheritance
                   color: Colors.transparent,
                   child: Container(
                     margin: const EdgeInsets.symmetric(horizontal: 40),
                     padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.9), // High opacity for cleanness
                       borderRadius: BorderRadius.circular(32),
                       border: Border.all(color: Colors.white, width: 2), // 3D White Lip
                       boxShadow: [
                         // Deep Purple Glow
                         BoxShadow(
                           color: const Color(0xFF8B5CF6).withOpacity(0.3),
                           blurRadius: 40,
                           spreadRadius: -5,
                           offset: const Offset(0, 20),
                         ),
                         // Tactile Shadow
                         BoxShadow(
                           color: Colors.black.withOpacity(0.1),
                           blurRadius: 15,
                           offset: const Offset(0, 10),
                         ),
                       ],
                     ),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         // Custom Spinner Container
                         Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: const Color(0xFFF3F4F6),
                             shape: BoxShape.circle,
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.black.withOpacity(0.05),
                                 blurRadius: 10,
                                 offset: const Offset(0, 4), // Inner depth feel
                                 spreadRadius: -2,
                               ),
                             ],
                           ),
                           child: const SizedBox(
                             height: 32, 
                             width: 32,
                             child: CircularProgressIndicator(
                               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)), // Violet
                               strokeWidth: 3,
                               backgroundColor: Colors.transparent,
                             ),
                           ),
                         ),
                         const SizedBox(height: 24),
                         Text(
                           "Crafting Report...",
                           style: GoogleFonts.plusJakartaSans(
                             color: const Color(0xFF1A1A1A),
                             fontSize: 18,
                             fontWeight: FontWeight.w700,
                             letterSpacing: -0.5,
                           ),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           "Analyzing your journey.",
                           style: GoogleFonts.plusJakartaSans(
                             color: const Color(0xFF6B7280),
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
            ],
          );
        },
      );

      // PERFORM EXPORT
      await ReportService().generateAndShare(entries, userName, limit, imagePath);

      // DISMISS LOADING
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Dismiss if error occurs
      if (mounted) Navigator.of(context).pop();
      
      debugPrint("Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  Future<void> _deleteData() async {
    // 1. First Warning
    final bool? firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildGlassDialog(
        context,
        title: "Clear Data?",
        message: "This will remove all your entries and settings. This action cannot be undone.",
        confirmLabel: "Delete",
        isDestructive: true,
      ),
    );

    if (firstConfirm != true) return;

    // 2. Second Warning (Double Confirm)
    final bool? secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildGlassDialog(
        context,
        title: "Final Check",
        message: "Are you absolutely sure? All data will be lost forever.",
        confirmLabel: "CONFIRM DELETE",
        isDestructive: true,
      ),
    );

    if (secondConfirm == true) {
      await DataService().repository.deleteAll();
      SettingsService().setUserName("Traveler");
      SettingsService().setProfileImage(null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All data erased.")));
        Navigator.pop(context);
      }
    }
  }

  Widget _buildGlassDialog(BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
    Widget? customContent,
    VoidCallback? onConfirm,
  }) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: Offset(0, 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
              if (customContent != null) customContent,
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("Cancel", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.black45)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (onConfirm != null) onConfirm();
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? Colors.redAccent : Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(confirmLabel, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToneSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Insight Tone", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _buildToneOption("Supportive", "Encouraging and warm.", Icons.favorite_rounded, Colors.pink),
            SizedBox(height: 12),
            _buildToneOption("Analytical", "Precise and data-driven.", Icons.bar_chart_rounded, Colors.blue),
            SizedBox(height: 12),
            _buildToneOption("Neutral", "Just the facts.", Icons.balance_rounded, Colors.grey),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToneOption(String title, String subtitle, IconData icon, Color color) {
    final isSelected = SettingsService().insightTone.value == title;
    return GestureDetector(
      onTap: () {
        SettingsService().setTone(title);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? color : Colors.grey.withOpacity(0.2),
              radius: 20,
              child: Icon(icon, color: isSelected ? Colors.white : Colors.black54, size: 20),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  // --- SECURITY ---
  
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      bool canCheckBiometrics = false;
      try {
        canCheckBiometrics = await auth.canCheckBiometrics;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Biometric hardware not available.")));
        return;
      }

      if (canCheckBiometrics) {
        try {
          final bool didAuthenticate = await auth.authenticate(
              localizedReason: 'Authenticate to enable biometric protection',
          );
          
          if (didAuthenticate) {
            SettingsService().setBiometric(true);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Authentication failed.")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Device does not support biometrics.")));
      }
    } else {
      SettingsService().setBiometric(false);
    }
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    // Listen to all settings to rebuild profile UI
    return AnimatedBuilder(
      animation: Listenable.merge([
        SettingsService().appearanceMode,
        SettingsService().insightTone,
        SettingsService().insightsEnabled,
        SettingsService().currency,
        SettingsService().userName,
        SettingsService().profileImagePath,
        SettingsService().monthlyLimit,
      ]),
      builder: (context, _) {
       return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: Colors.transparent, // Mandate: Transparent header to show gradient
                child: AppBar(
                  title: Text("Profile", style: GoogleFonts.plusJakartaSans(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700)),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // 1. LIGHT BASE (Standard)
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

            // 4. CONTENT
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 100, 24, 40),
              child: Column(
                children: [
                  _buildIdentitySection(),
                  SizedBox(height: 32),

                  _buildSectionLabel("APPEARANCE"),
                  SizedBox(height: 12),
                  _buildGlassCard(child: _buildAppearanceToggle(SettingsService().appearanceMode.value)),
                  SizedBox(height: 32),

                  _buildSectionLabel("PREFERENCES"),
                  SizedBox(height: 12),
                  // 1. Insights Toggle
                  _buildGlassCard(
                     child: _buildSwitchRow(
                       "Behavioral Insights", 
                       "AI-powered financial pattern analysis",
                       SettingsService().insightsEnabled.value, 
                       (v) => SettingsService().toggleInsights(v)
                     )
                  ),
                  SizedBox(height: 12),
                  
                  // 1. Biometric Security (Migrated from System Hub)
                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsService().biometricEnabled,
                    builder: (context, enabled, _) {
                      return _buildGlassCard(
                        child: _buildSwitchRow(
                          "Biometric Lock", 
                          "Secure app on launch", // Refined description
                          enabled, 
                          (v) => _toggleBiometrics(v)
                        )
                      );
                    }
                  ),
                  SizedBox(height: 12),

                  // 2. Insight Tone
                  _buildGlassCard(
                     child: _buildActionRow("Insight Tone", Icons.tune_rounded, 
                            trailingText: SettingsService().insightTone.value,
                            onTap: _showToneSelector)
                  ),
                  SizedBox(height: 12),

                  // 3. Currency
                  _buildGlassCard(
                     child: _buildOptionRow("Currency", SettingsService().currency.value, ["₹", "\$", "€", "£"], (v) => SettingsService().setCurrency(v))
                  ),
                  SizedBox(height: 12),
                  
                  // 4. Monthly Goal
                  _buildGlassCard(
                     child: ValueListenableBuilder<double>(
                       valueListenable: SettingsService().monthlyLimit,
                       builder: (context, limit, _) => _buildSliderRow(context, "Monthly Goal", limit, 
                          (v) {
                             double rounded = (v / 500).round() * 500.0;
                             if (rounded < 1000) rounded = 1000;
                             SettingsService().setLimit(rounded);
                          }),
                     ),
                  ),
                  SizedBox(height: 32),

                  _buildSectionLabel("DATA & PRIVACY"),
                  SizedBox(height: 12),
                  _buildGlassCard(
                     child: _buildActionRow("Export Data", Icons.download_rounded, onTap: _exportData)
                  ),
                  SizedBox(height: 12),
                  _buildGlassCard(
                     child: _buildActionRow("Delete All Data", Icons.delete_outline_rounded, isDestructive: true, onTap: _deleteData)
                  ),
                  SizedBox(height: 48),
                  _buildFooter(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );
      }
    );
  }

  Widget _buildIdentitySection() {
    final imagePath = SettingsService().profileImagePath.value;
    final name = SettingsService().userName.value;
    
    return Column(
      children: [
          ValueListenableBuilder<AppearanceMode>(
            valueListenable: SettingsService().appearanceMode,
            builder: (context, mode, _) {
              final isSharp = mode == AppearanceMode.sharp;
              final double radius = isSharp ? 0.0 : 64.0; // 0 for Square, 64 for Circle
              
              return GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radius), // Sharp or Round
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius), // Sharp or Round
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFE1BEE7).withOpacity(0.3), // Fallback color
                        image: imagePath != null 
                          ? DecorationImage(
                              image: FileImage(File(imagePath)), 
                              fit: BoxFit.cover
                            )
                          : null,
                      ),
                      child: imagePath == null 
                        ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : "U", style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))))
                        : null,
                    ),
                  ),
                ),
              );
            }
          ),
          SizedBox(height: 8),
          Text("Tap to change photo", style: TextStyle(fontSize: 10, color: Colors.black38)),
        SizedBox(height: 16),
        
        Material(
          color: Colors.transparent,
          child: ValueListenableBuilder<AppearanceMode>(
            valueListenable: SettingsService().appearanceMode,
            builder: (context, mode, _) {
               final isSharp = mode == AppearanceMode.sharp;
               final double radius = isSharp ? 0.0 : 30.0;
               return InkWell(
                onTap: _editName,
                borderRadius: BorderRadius.circular(radius),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
                    boxShadow: [
                       BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 1, offset: Offset(0, -1)),
                       BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.edit_rounded, size: 16, color: Color(0xFF9C27B0)),
                    ],
                  ),
                ),
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF1A1A1A).withOpacity(0.4),
            ),
          ),
        ),
      );
  }

  Widget _buildGlassCard({required Widget child}) {
    final isSharp = SettingsService().appearanceMode.value == AppearanceMode.sharp;
    final double radius = isSharp ? 0.0 : 24.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
             boxShadow: [
                BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 2, offset: Offset(0, -1)),
             ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAppearanceToggle(AppearanceMode currentMode) {
    // 0: Soft, 1: Sharp
    final bool isSharp = currentMode == AppearanceMode.sharp;
    final double radius = isSharp ? 0.0 : 16.0;
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          // Sliding Indicator
          AnimatedAlign(
            alignment: isSharp ? Alignment.centerRight : Alignment.centerLeft,
            duration: Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSharp ? 0.0 : 12.0),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                height: double.infinity,
              ),
            ),
          ),
          
          // Text Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => SettingsService().setAppearance(AppearanceMode.soft),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: Duration(milliseconds: 200),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: !isSharp ? FontWeight.w700 : FontWeight.w500,
                        color: Color(0xFF1A1A1A).withOpacity(!isSharp ? 1.0 : 0.5),
                        fontSize: 14,
                      ),
                      child: Text("Soft"),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                   behavior: HitTestBehavior.opaque,
                  onTap: () => SettingsService().setAppearance(AppearanceMode.sharp),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: Duration(milliseconds: 200),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: isSharp ? FontWeight.w700 : FontWeight.w500,
                        color: Color(0xFF1A1A1A).withOpacity(isSharp ? 1.0 : 0.5),
                        fontSize: 14,
                      ),
                      child: Text("Sharp"),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, String sublabel, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                if (sublabel.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(sublabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black45)),
                ]
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: Switch.adaptive(value: value, onChanged: onChanged, activeColor: Color(0xFF9C27B0)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String label, IconData icon, {bool isDestructive = false, String? trailingText, VoidCallback? onTap}) {
     return InkWell(
       onTap: onTap,
       child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.redAccent : Color(0xFF1A1A1A), size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.redAccent : Color(0xFF1A1A1A),
              ),
            ),
            Spacer(),
            if (trailingText != null) 
              Text(trailingText, style: TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w500)),
            if (trailingText != null) SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF1A1A1A).withOpacity(0.3)),
          ],
        ),
      ),
     );
  }
  
  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Currency", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _buildCurrencyOption("₹", "Indian Rupee"),
            SizedBox(height: 12),
            _buildCurrencyOption("\$", "US Dollar"),
            SizedBox(height: 12),
            _buildCurrencyOption("€", "Euro"),
            SizedBox(height: 12),
            _buildCurrencyOption("£", "British Pound"),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String symbol, String name) {
    final isSelected = SettingsService().currency.value == symbol;
    return GestureDetector(
      onTap: () {
        SettingsService().setCurrency(symbol);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF9C27B0).withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Color(0xFF9C27B0) : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? Color(0xFF9C27B0) : Colors.grey.withOpacity(0.2),
              radius: 20,
              child: Text(symbol, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            SizedBox(width: 16),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: Color(0xFF9C27B0)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(String label, String value, List<String> options, ValueChanged<String> onChanged) {
     return InkWell(
       onTap: _showCurrencySelector, // Trigger the new sheet
       child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A1A1A).withOpacity(0.5), size: 20),
              ],
            ),
          ],
        ),
      ),
     );
  }
  
  Widget _buildSliderRow(BuildContext context, String label, double value, ValueChanged<double> onChanged) {
    // Treat any value > 50k as 50k for slider position purposes
    final sliderValue = value > 50000 ? 50000.0 : value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16), // Reduced padding to increase width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding( // Keep label and value aligned with other items
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                GestureDetector(
                  onTap: () => _showLimitEntryDialog(context, value),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text("₹${value.toStringAsFixed(0)}", style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF9C27B0))),
                        SizedBox(width: 4),
                        Icon(Icons.edit_rounded, size: 12, color: Color(0xFF9C27B0)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Color(0xFF9C27B0),
              inactiveTrackColor: Color(0xFF9C27B0).withOpacity(0.2),
              thumbColor: Color(0xFF9C27B0),
              overlayColor: Color(0xFF9C27B0).withOpacity(0.1),
              trackHeight: 2, 
            ),
            child: Slider(
              value: sliderValue, 
              min: 1000, 
              max: 50000, 
              divisions: 98, 
              onChanged: (val) {
                // Haptic Logic: Only trigger if the value has actually changed enough (based on division step)
                if (val != sliderValue) {
                   HapticFeedback.selectionClick(); // Use selectionClick for slider ticks
                   onChanged(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLimitEntryDialog(BuildContext context, double currentValue) {
    final controller = TextEditingController(text: currentValue.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => _buildGlassDialog(
        context,
        title: "Set Monthly Goal",
        message: "Enter your desired monthly spending limit.",
        confirmLabel: "Set Limit",
        customContent: Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: "₹",
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        onConfirm: () {
          final val = double.tryParse(controller.text);
          if (val != null && val >= 1000) {
            SettingsService().setLimit(val);
          }
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tiny Logo
            Container(
              width: 24, 
              height: 24, 
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.0, 
                  child: Image.asset('assets/images/savora_logo_clean.png')
                ),
              ),
            ),
            SizedBox(width: 10), // Increased spacing
            Text(
              "Savora",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20, // Increased
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A).withOpacity(0.6), // Slightly darker
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 8), // Increased
        Text(
          "Private • Local • v1.2.0",
           style: GoogleFonts.plusJakartaSans(
             fontSize: 11, // Increased
             fontWeight: FontWeight.w600,
             color: Color(0xFF1A1A1A).withOpacity(0.3), 
             letterSpacing: 0.5,
           ),
        ),
        SizedBox(height: 12), // Increased spacing before credit
        Text(
          "Crafted by Anand Choubey",
          style: GoogleFonts.plusJakartaSans( // Switched to specific font
            fontSize: 13, // Increased from 10
            color: Color(0xFF9C27B0), // Exact match to Slider/Toggle Purple
            fontWeight: FontWeight.w700, // Bolder
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 32), // More bottom padding
      ],
    );
  }
}
