import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';
import '../theme/core_theme.dart';
import '../widgets/core_drawer.dart';
import '../data/settings_service.dart';
import '../widgets/glass_onboarding_dialog.dart';

class ContextArchiveScreen extends StatefulWidget {
  // Mandate: No const
  ContextArchiveScreen({super.key});

  @override
  State<ContextArchiveScreen> createState() => _ContextArchiveScreenState();
}

class _ContextArchiveScreenState extends State<ContextArchiveScreen> {
  int _sortOption = 0; // 0 = Highest Spend (₹), 1 = Most Frequent (#)
  Map<String, _VaultData>? _vaultData;

  @override
  void initState() {
    super.initState();
    _loadVault();
    
    // Check Onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenVaultOnboarding.value) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GlassOnboardingDialog(
            title: "The Vault",
            description: "Your financial history in one place.\n\nToggle between 'Amount' to see where money went, and 'Frequency' to see where your habits lie.",
            icon: Icons.history_edu_rounded,
            accentColor: Color(0xFF10B981), // Emerald Green for Money/History
            onDismiss: () {
              Navigator.pop(context);
              SettingsService().setHasSeenVaultOnboarding(true);
            },
          ),
        );
      }
    });
  }

  Future<void> _loadVault() async {
    final entries = await DataService().repository.getEntries();
    final data = <String, _VaultData>{};

    for (var e in entries) {
      if (e.context.isEmpty) continue;
      final key = e.context;
      
      if (!data.containsKey(key)) {
        data[key] = _VaultData(context: key, totalSpend: 0, count: 0, entries: []);
      }
      
      data[key]!.totalSpend += e.amount.abs();
      data[key]!.count += 1;
      data[key]!.entries.add(e);
    }
    
    for (var v in data.values) {
      v.entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    if (mounted) {
      setState(() {
        _vaultData = data;
      });
    }
  }

  List<_VaultData> get _sortedList {
    if (_vaultData == null) return [];
    final list = _vaultData!.values.toList();
    if (_sortOption == 0) {
      list.sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
    } else {
      list.sort((a, b) => b.count.compareTo(a.count));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F3FF),
      drawer: CoreDrawer(),
      body: Stack(
        children: [
          // 1. LIGHT BASE
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

          CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              // 1. Vanishing Header & Toggle
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true, // Added snap
                pinned: false, // Mandate: Vanish on scroll
                centerTitle: true, // Added centerTitle
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
                  "The Vault",
                  style: GoogleFonts.plusJakartaSans(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 10)),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 3D-Glass Smart Toggle (Replacing Title)
                      _VaultToggle(
                        selectedIndex: _sortOption,
                        onChanged: (val) => setState(() => _sortOption = val),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 32)),

              // 2. Data Grid
              if (_vaultData == null)
                SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (_vaultData!.isEmpty)
                 SliverFillRemaining(
                   child: Center(
                     child: Text(
                       "Vault is empty.",
                       style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.w600),
                     ),
                   ),
                 )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16, // Wide spacing
                      mainAxisSpacing: 24,  // Deep spacing
                      childAspectRatio: 0.85, 
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = _sortedList[index];
                        return _VaultCard(data: data);
                      },
                      childCount: _sortedList.length,
                    ),
                  ),
                ),
                
               SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultData {
  final String context;
  double totalSpend;
  int count;
  final List<ReflectionEntry> entries;

  _VaultData({
    required this.context,
    required this.totalSpend,
    required this.count,
    required this.entries,
  });
}

// --- NEW COMPONENTS ---

class _VaultToggle extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  // Mandate: No const
  _VaultToggle({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppearanceMode>(
      valueListenable: SettingsService().appearanceMode,
      builder: (context, mode, _) {
        final isSharp = mode == AppearanceMode.sharp;
        final double radius = isSharp ? 0.0 : 20.0;

        // Compact Sliding Pill
        return Container(
          width: 180, // Compact width
          height: 40,
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
              // The Pill
              AnimatedAlign(
                duration: Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                alignment: selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 90, // Half width
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)], // Pink-Purple Gradient
                    ),
                    boxShadow: [
                       BoxShadow(
                         color: Color(0xFF8B5CF6).withOpacity(0.3),
                         blurRadius: 8,
                         offset: Offset(0, 2)
                       ),
                    ],
                  ),
                ),
              ),
              
              // Options (Icons)
              Row(
                children: [
                  _buildOption(0, Icons.currency_rupee_rounded),
                  _buildOption(1, Icons.tag_rounded),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildOption(int index, IconData icon) {
    final bool isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : Color(0xFF1A1A1A).withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class _VaultCard extends StatelessWidget {
  final _VaultData data;

  // Mandate: No const
  _VaultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Determine Icon based on context
    // Determine Icon based on context
    IconData icon;
    switch (data.context) {
      case 'Home': icon = Icons.home_rounded; break;
      case 'Food': icon = Icons.fastfood_rounded; break;
      case 'Travel': icon = Icons.flight_rounded; break;
      case 'Social': icon = Icons.groups_rounded; break;
      case 'Work': icon = Icons.work_rounded; break;
      case 'Shopping': icon = Icons.shopping_bag_rounded; break;
      case 'Online': icon = Icons.public_rounded; break;
      default: icon = Icons.folder_open_rounded;
    }

    return ValueListenableBuilder<AppearanceMode>(
      valueListenable: SettingsService().appearanceMode,
      builder: (context, mode, _) {
        final isSharp = mode == AppearanceMode.sharp;
        final double radius = isSharp ? 0.0 : 28.0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _FilteredVaultScreen(data: data)),
            );
          },
          child: Container(
            // Jewelry Depth: Deep Shadow
            decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(radius),
               boxShadow: [
                 BoxShadow(
                   color: Color(0xFF7C3AED).withOpacity(0.12), // Deep Violet shadow
                   offset: Offset(0, 12),
                   blurRadius: 24,
                   spreadRadius: -4,
                 ),
               ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Heavy Glass
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85), // High opacity for solid glass look
                    borderRadius: BorderRadius.circular(radius),
                    // 0.5px Pink-to-Purple Glow is simulated via a Gradient Border Container inside Stack
                  ),
                  child: Stack(
                    children: [
                       // The Gradient Border
                       Positioned.fill(
                         child: Container(
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(radius),
                             border: Border.all(
                               color: Color(0xFFD946EF).withOpacity(0.4), // Pinkish-Purple
                               width: 0.8, // Slightly thicker than 0.5 to be visible on high-res
                             ),
                           ),
                         ),
                       ),

                   Padding(
                     padding: EdgeInsets.all(24),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         // Category Icon
                         Container(
                           padding: EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Color(0xFFF3E8FF), // Light Lilac
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             icon, 
                             color: Color(0xFF7C3AED), 
                             size: 20,
                           ),
                         ),
                         
                         Spacer(),
                         
                         // Category Name
                         Text(
                           data.context,
                           style: GoogleFonts.plusJakartaSans(
                             fontSize: 17,
                             fontWeight: FontWeight.w700,
                             color: Color(0xFF1A1A1A),
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                         
                         SizedBox(height: 4),
                         
                         // Entry Count
                         Text(
                           "${data.count} entries",
                           style: GoogleFonts.plusJakartaSans(
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                             color: Color(0xFF1A1A1A).withOpacity(0.5),
                           ),
                         ),

                         SizedBox(height: 12),
                         
                         // Total Spend (Bold & 100% Opacity)
                         Text(
                           "₹${data.totalSpend.toStringAsFixed(0)}",
                           style: GoogleFonts.plusJakartaSans(
                             fontSize: 20,
                             fontWeight: FontWeight.w800, // Extra Bold
                             color: Color(0xFF1A1A1A), // 100% Opacity
                             letterSpacing: -0.5,
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
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
    );
      }
    );
  }
}

class _FilteredVaultScreen extends StatelessWidget {
  final _VaultData data;

  // Mandate: No const
  _FilteredVaultScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent Scaffold
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

          // CONTENT
          CustomScrollView(
            physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              data.context,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black, 
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          
          SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final e = data.entries[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy • h:mm a').format(e.timestamp),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10, 
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  e.note.isEmpty ? "No description" : e.note,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, 
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "₹${e.amount.abs().toStringAsFixed(0)}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, 
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: data.entries.length,
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}
