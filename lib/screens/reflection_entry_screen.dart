import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';
import '../theme/core_theme.dart';
import '../widgets/expressive_widgets.dart'; // Added for UnifiedProButton

class ReflectionEntryScreen extends StatefulWidget {
  const ReflectionEntryScreen({super.key});

  @override
  State<ReflectionEntryScreen> createState() => _ReflectionEntryScreenState();
}

class _ReflectionEntryScreenState extends State<ReflectionEntryScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Default to null (Empty state)
  String? _selectedMood;
  String? _selectedContext;
  
  // Data Maps
  final Map<String, IconData> _moodIcons = {
    'Calm': Icons.wb_cloudy_rounded,
    'Tired': Icons.bedtime_rounded,
    'Stressed': Icons.bolt_rounded,
    'Focused': Icons.auto_awesome_rounded,
    'Regretful': Icons.broken_image_rounded, 
    'Impulsive': Icons.flash_on_rounded,
    // "Anxious" removed
  };
  
  final Map<String, IconData> _contextIcons = {
    'Home': Icons.home_rounded,
    'Work': Icons.work_rounded,
    'Cafe': Icons.coffee_rounded,
    'Social': Icons.people_rounded,
    'Travel': Icons.directions_bus_rounded,
    'Online': Icons.language_rounded,
  };

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFDFD), 
      appBar: AppBar(
        // MATCHING INTENT SCREEN: Size 20, w800, Dark Color
        title: Text(
          "NEW ENTRY", 
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF1A1A1A)
          )
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0), 
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true, 
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 60), 
                    
                     Text(
                       "HOW MUCH?",
                       style: GoogleFonts.plusJakartaSans(
                         fontSize: 12, // Increased from 10
                         fontWeight: FontWeight.w800,
                         color: Colors.black26, 
                         letterSpacing: 3.0, // Increased spacing slightly
                       ),
                     ),
                     SizedBox(height: 32),
                     
                     // 2. HERO INPUT ROW (Native Cursor)
                     IntrinsicWidth(
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0), 
                              child: Text(
                                "₹",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900, // Max Bold
                                  color: Colors.black26, 
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            
                            // Input with Native TALL PINK CURSOR
                            IntrinsicWidth(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                autofocus: true,
                                // NATIVE CURSOR CONFIGURATION
                                cursorColor: Color(0xFFEC4899),
                                cursorWidth: 3.0,
                                cursorHeight: 80.0, 
                                cursorRadius: Radius.circular(2),
                                textAlign: TextAlign.left,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 90,
                                    fontWeight: FontWeight.w900, // Max Bold
                                    color: Colors.black.withOpacity(0.06), 
                                    height: 1.0,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 90,
                                  fontWeight: FontWeight.w900, // Max Bold
                                  color: Color(0xFF1A1A1A), 
                                  height: 1.0,
                                ),
                              ),
                            ),
                         ],
                       ),
                     ),
                     
                     SizedBox(height: 80), 
                     
                     // 3. SELECTORS 
                     Row(
                       children: [
                         Expanded(
                           child: _MainScreenSelector(
                             label: _selectedMood ?? "Context",
                             icon: _selectedMood != null ? (_moodIcons[_selectedMood] ?? Icons.face_rounded) : Icons.face_retouching_natural_rounded,
                             active: _selectedMood != null,
                             onTap: () => _showDialogSelection(
                               title: "SELECT CONTEXT",
                               items: _moodIcons,
                               onSelected: (val) => setState(() => _selectedMood = val),
                             ),
                           ),
                         ),
                         SizedBox(width: 20),
                         Expanded(
                           child: _MainScreenSelector(
                             label: _selectedContext ?? "Place",
                             icon: _selectedContext != null ? (_contextIcons[_selectedContext] ?? Icons.place_rounded) : Icons.place_outlined,
                             active: _selectedContext != null,
                             onTap: () => _showDialogSelection(
                               title: "SELECT PLACE",
                               items: _contextIcons,
                               onSelected: (val) => setState(() => _selectedContext = val),
                             ),
                           ),
                         ),
                       ],
                     ),
                     
                     SizedBox(height: 40),
                     
                     // 4. REFLECTION 
                     Container(
                       padding: EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: Colors.white, 
                         borderRadius: BorderRadius.circular(24),
                         boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: Offset(0, 5))
                         ]
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Row(
                              children: [
                                Icon(Icons.notes_rounded, size: 16, color: Color(0xFFEC4899)),
                                SizedBox(width: 12),
                                Text(
                                  "REFLECTION", 
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w800, 
                                    letterSpacing: 2, 
                                    color: Colors.black38
                                  )
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _noteController,
                              maxLines: 3,
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A), height: 1.5),
                              decoration: InputDecoration(
                                hintText: "What was the whisper of this moment?",
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: Colors.black26, 
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                         ],
                       ),
                     ),
                  ],
                ),
              ),
            ),
            
            // 5. SAVE BUTTON (UnifiedProButton Match)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                 padding: EdgeInsets.only(bottom: 24, top: 0),
                 child: UnifiedProButton(
                   text: "Save",
                   onTap: _saveEntry,
                   // Exact Gradient from Home Screen
                   gradientColors: [
                      Color(0xFFBB86FC).withOpacity(0.6), 
                      Color(0xFFCF6679).withOpacity(0.6)
                   ],
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialogSelection({
    required String title,
    required Map<String, IconData> items,
    required Function(String) onSelected,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4), 
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, 
        insetPadding: EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Color(0xFFF9FAFB), 
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 2, 
                  color: Colors.black38
                )
              ),
              SizedBox(height: 32),
              
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  mainAxisSpacing: 16, 
                  crossAxisSpacing: 16, 
                  childAspectRatio: 1.3 
                ),
                itemBuilder: (context, index) {
                  final key = items.keys.elementAt(index);
                  final icon = items[key]!;
                  return GestureDetector(
                    onTap: () {
                      onSelected(key);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100], 
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Color(0xFF8B5CF6), size: 28), 
                          SizedBox(height: 12),
                          Text(
                            key, 
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, 
                              fontWeight: FontWeight.w700, 
                              color: Color(0xFF1A1A1A)
                            )
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    
    final amount = double.tryParse(amountText) ?? 0.0;
    
    // Save empty string if not selected
    final entry = ReflectionEntry(
      id: Uuid().v4(),
      amount: -amount.abs(),
      currencyCode: 'INR',
      timestamp: DateTime.now(),
      mood: _selectedMood ?? '', // Empty string if null
      context: _selectedContext ?? '', // Empty string if null
      note: _noteController.text.trim(),
    );
    
    await DataService().repository.saveEntry(entry);
    if (mounted) Navigator.pop(context, true);
  }
}

// Visual Replica of Main Screen Selection Buttons (Image 2)
class _MainScreenSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  
  const _MainScreenSelector({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70, // Tall and Pill-like
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // Highly rounded
          border: Border.all(color: active ? Color(0xFF8B5CF6).withOpacity(0.3) : Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B5CF6).withOpacity(active ? 0.1 : 0.03), 
              blurRadius: 20, 
              offset: Offset(0, 8),
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: active ? Color(0xFF8B5CF6) : Colors.black26, 
              size: 20
            ),
            SizedBox(width: 12),
            Text(
              label, 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, 
                fontWeight: FontWeight.w700, 
                color: active ? Color(0xFF1A1A1A) : Colors.black45
              )
            ),
          ],
        ),
      ),
    );
  }
}
