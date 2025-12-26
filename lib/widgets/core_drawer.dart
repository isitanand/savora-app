import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/daily_stream_screen.dart'; // Added Home Import
import '../screens/context_archive_screen.dart';
import '../screens/data_transparency_screen.dart';
import '../screens/the_forge_screen.dart';
import '../screens/monthly_intent_screen.dart';
import '../screens/pattern_view_screen.dart';
import '../screens/quiet_space_screen.dart';
import '../screens/favors_screen.dart'; // Added Favors Import
import '../screens/data_backup_screen.dart'; // Added Data Backup Import
import '../data/settings_service.dart'; 

class CoreDrawer extends StatelessWidget {
  CoreDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Mandate: 80% screen width
    final double drawerWidth = MediaQuery.of(context).size.width * 0.8;
    // Mandate: Route Awareness
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return ValueListenableBuilder<AppearanceMode>(
      valueListenable: SettingsService().appearanceMode,
      builder: (context, mode, _) {
        // Mandate: Softer corners even in "Sharp" mode for premium feel - OVERRIDDEN for Sharp Mode
        final isSharp = mode == AppearanceMode.sharp;
        final double radius = isSharp ? 0.0 : 36.0;

        return Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          width: drawerWidth,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(radius),
              bottomRight: Radius.circular(radius),
            ),
          ),
          child: Stack(
            children: [
              // 1. Structural Glass DNA - The Blur
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
                  child: Stack(
                    children: [
                      // ATMOSPHERIC ORBS (Enhanced)
                      Positioned(
                        top: -100,
                        left: -50,
                        child: Container(
                          width: 400,
                          height: 400,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF90CAF9).withOpacity(0.35), // Blue (Stronger)
                            boxShadow: [BoxShadow(color: Color(0xFF90CAF9).withOpacity(0.2), blurRadius: 100)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 200,
                        right: -100,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCE93D8).withOpacity(0.25), // Purple (Subtler)
                            boxShadow: [BoxShadow(color: Color(0xFFCE93D8).withOpacity(0.2), blurRadius: 80)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 50,
                        left: -50,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF80DEEA).withOpacity(0.2), // Cyan/Teal for depth
                            boxShadow: [BoxShadow(color: Color(0xFF80DEEA).withOpacity(0.15), blurRadius: 60)],
                          ),
                        ),
                      ),
    
                      // The Blur
                      BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0), // Mandate: sigma 30
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    
              // 2. Base Layer with Milky Effect (Optimized)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75), // Slightly more transparency for depth
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(radius),
                      bottomRight: Radius.circular(radius),
                    ),
                  ),
                ),
              ),
    
              // 3. Scrim - 3D Frost Depth
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.7), // Stronger highlight
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      stops: [0.0, 0.3, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(radius),
                      bottomRight: Radius.circular(radius),
                    ),
                    // Glass Border Overlay
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.0,
                    ),
                  ),
                ),
              ),

          // 4. Content Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Header - BREATHABLE
                Padding(
                  padding: EdgeInsets.fromLTRB(32, 60, 32, 40), // Generous top/bottom padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Container(
                        padding: EdgeInsets.all(3), 
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF7C3AED).withOpacity(0.2),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            width: 64, // Standard Premium Size
                            height: 64,
                            color: Colors.white,
                            child: Transform.scale(
                              scale: 1.0, 
                              child: Image.asset(
                                'assets/images/savora_logo_clean.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24), // Increased from 16
                      Text(
                        "SAVORA",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30, 
                          fontWeight: FontWeight.w900, 
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -1.0,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Self-Aware Personal Finance", 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, 
                          fontWeight: FontWeight.w500, 
                          color: Color(0xFF1A1A1A).withOpacity(0.5),
                          letterSpacing: 0.5, 
                        ),
                      ),
                    ],
                  ),
                ),

                // Seamless Navigation
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("EXPLORE"),
                        SizedBox(height: 8),
                        _GlassNavItem(
                          icon: Icons.grid_view_rounded,
                          label: "Home",
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            if (currentRoute != null && currentRoute != '/') {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => DailyStreamScreen()),
                                (route) => false,
                              );
                            }
                          },
                          isActive: currentRoute == null || currentRoute == '/', 
                          isSharp: isSharp,
                        ),
                        SizedBox(height: 16), // Breathable Gap
                         _GlassNavItem(
                            icon: Icons.pie_chart_rounded, 
                            label: "Analytics", 
                            onTap: () => _nav(context, PatternViewScreen(), '/analytics', isSharp), 
                            isActive: currentRoute == '/analytics',
                            isSharp: isSharp
                        ),
                        SizedBox(height: 16),
                        _GlassNavItem(
                            icon: Icons.lightbulb_circle_rounded, 
                            label: "Intent", 
                            onTap: () => _nav(context, MonthlyIntentScreen(), '/intent', isSharp), 
                            isActive: currentRoute == '/intent',
                            isSharp: isSharp
                        ),
                        SizedBox(height: 16),
                        _GlassNavItem(
                            icon: Icons.folder_open_rounded, 
                            label: "The Vault", 
                            onTap: () => _nav(context, ContextArchiveScreen(), '/archive', isSharp), 
                            isActive: currentRoute == '/archive',
                            isSharp: isSharp
                        ),
                        SizedBox(height: 16),
                        _GlassNavItem(
                            icon: Icons.volunteer_activism_rounded, 
                            label: "Favors", 
                            onTap: () => _nav(context, FavorsScreen(), '/favors', isSharp), 
                            isActive: currentRoute == '/favors',
                            isSharp: isSharp
                        ),

                        SizedBox(height: 48), // Large breathy section gap
                        
                        // Mandate: The Thin Violet Line Divider
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6).withOpacity(0.0),
                                  Color(0xFFD946EF).withOpacity(0.4),
                                  Color(0xFF8B5CF6).withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 48), // Large breathy section gap

                        _buildSectionHeader("MINDFULNESS"),
                        SizedBox(height: 8),
                        _GlassNavItem(
                           icon: Icons.self_improvement_rounded, 
                           label: "Quiet Space", 
                           onTap: () => _nav(context, QuietSpaceScreen(), '/quiet', isSharp), 
                           isActive: currentRoute == '/quiet',
                           isSharp: isSharp
                        ),
                        SizedBox(height: 16),
                        _GlassNavItem(
                           icon: Icons.emoji_events_rounded, 
                           label: "The Forge", 
                           onTap: () => _nav(context, TheForgeScreen(), '/forge', isSharp), 
                           isActive: currentRoute == '/forge',
                           isSharp: isSharp,
                           iconSize: 18.0,
                        ),

                        SizedBox(height: 48),

                        // Mandate: The Thin Violet Line Divider (Replicated for Data)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6).withOpacity(0.0),
                                  Color(0xFFD946EF).withOpacity(0.4),
                                  Color(0xFF8B5CF6).withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 48),

                        // DATA SECTION
                        _buildSectionHeader("DATA"),
                        SizedBox(height: 8),
                        _GlassNavItem(
                           icon: Icons.settings_backup_restore_rounded, 
                           label: "Data & Backups", 
                           onTap: () => _nav(context, DataBackupScreen(), '/backup', isSharp), 
                           isActive: currentRoute == '/backup',
                           isSharp: isSharp
                        ),

                        SizedBox(height: 60), // Generous Bottom Margin
                      ],
                    ),
                  ),
                ),
                // FOOTER REMOVED
              ],
            ),
          ),
        ],
      ),
    );
  },
);
  }

  void _nav(BuildContext context, Widget screen, String routeName, bool isSharp) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => screen,
      settings: RouteSettings(name: routeName),
    ));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 20, bottom: 4, top: 0), 
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11, 
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5, 
          color: Color(0xFF1A1A1A).withOpacity(0.35),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isSharp;
  final double iconSize;

  const _GlassNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isSharp = false,
    this.iconSize = 22.0,
  });

  @override
  State<_GlassNavItem> createState() => _GlassNavItemState();
}

class _GlassNavItemState extends State<_GlassNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Mandate: Active State = 100% Opacity 3D-Glass Pill
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          // BREATY VERTICAL PADDING (18)
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18), 
          decoration: widget.isActive
              ? BoxDecoration(
                  color: Colors.white, // Pure white active
                  borderRadius: BorderRadius.circular(widget.isSharp ? 0 : 24), // Rounder
                  border: Border.all(
                    width: 1.0,
                    color: Colors.white,
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF8B5CF6).withOpacity(0.15), blurRadius: 20, offset: Offset(0, 8)),
                    BoxShadow(color: Color(0xFFEC4899).withOpacity(0.1), blurRadius: 10, offset: Offset(0, 2)),
                  ]
                )
              : BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.isSharp ? 0 : 24),
                ),
          child: Row(
            children: [
              // FIXED WIDTH CONTAINER FOR ICON
              Container(
                width: 24, 
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.isActive
                      ? Color(0xFF7C3AED)
                      : Color(0xFF1A1A1A).withOpacity(0.6), 
                ),
              ),
              SizedBox(width: 20), // Wider text gap
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, // Slightly larger text
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600, 
                  color: widget.isActive
                      ? Color(0xFF7C3AED)
                      : Color(0xFF1A1A1A).withOpacity(0.7),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
