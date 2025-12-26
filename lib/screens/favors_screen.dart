import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/expressive_widgets.dart';
import '../widgets/glass_onboarding_dialog.dart'; // Added Import
import '../data/data_service.dart';
import '../data/settings_service.dart'; // Added Import
import '../data/models/reflection_entry.dart';
import '../widgets/core_drawer.dart';
import 'dart:ui' as ui;

// --- MODEL FOR GROUPING ---
class PersonDebt {
  final String name; // Display Name (Title Case)
  final double totalAmount;
  final List<ReflectionEntry> entries;

  PersonDebt({required this.name, required this.totalAmount, required this.entries});
}

class FavorsScreen extends StatefulWidget {
  const FavorsScreen({super.key});

  @override
  State<FavorsScreen> createState() => _FavorsScreenState();
}

class _FavorsScreenState extends State<FavorsScreen> {
  List<PersonDebt> _groupedDebts = [];
  double _totalOutstanding = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService().hasSeenFavorsOnboarding.value) {
        _showOnboarding();
      }
    });
    _loadData();
  }

  void _showOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlassOnboardingDialog(
        title: "Track Your Favors",
        description: "Keep a transparent record of who owes you what.\n\nGrouped by person, tracked by history. Settle debts when they're returned, or forgive them entirely.",
        icon: Icons.volunteer_activism_rounded,
        accentColor: Color(0xFFD946EF), // Pink
        onDismiss: () {
          SettingsService().setHasSeenFavorsOnboarding(true);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Future<void> _loadData() async {
    final allEntries = await DataService().repository.getEntries();
    
    // Filter: Include Settled items now, just ensure they have a name
    final userFavors = allEntries.where((e) => 
      e.personName != null && e.personName!.isNotEmpty
    ).toList();

    // Grouping Logic (Case Insensitive)
    final Map<String, List<ReflectionEntry>> map = {};
    for (var e in userFavors) {
      final key = e.personName!.trim().toLowerCase(); 
      if (!map.containsKey(key)) map[key] = [];
      map[key]!.add(e);
    }

    final List<PersonDebt> grouped = [];
    double globalTotal = 0;

    map.forEach((key, entries) {
      // Calculate Total: Only Active Items
      double personTotal = entries.where((e) => !e.isSettled).fold(0, (sum, e) => sum + e.amount.abs());
      
      // Sort Entries: Active first (Newest->Oldest), then Settled (Newest->Oldest)
      entries.sort((a, b) {
        if (a.isSettled != b.isSettled) {
          return a.isSettled ? 1 : -1; // Active (false) comes before Settled (true)
        }
        return b.timestamp.compareTo(a.timestamp); // Newest first
      });

      String displayName = _capitalize(entries.first.personName!.trim());
      
      // Only add to list if there are entries (which there always are if in map)
      // Check: Should we hide people with ONLY settled debts? 
      // User said "show history", so likely kept visible but with 0 total.
      grouped.add(PersonDebt(name: displayName, totalAmount: personTotal, entries: entries));
      
      globalTotal += personTotal;
    });

    // Sort People: Highest Active Debt first, then alphabetically
    grouped.sort((a, b) {
      if (b.totalAmount != a.totalAmount) return b.totalAmount.compareTo(a.totalAmount);
      return a.name.compareTo(b.name);
    });

    if (mounted) {
      setState(() {
        _groupedDebts = grouped;
        _totalOutstanding = globalTotal;
        _isLoading = false;
      });
    }
  }

  Future<void> _addEntry(String name, double amount, String note) async {
    final newEntry = ReflectionEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount, 
      currencyCode: 'INR',
      timestamp: DateTime.now(),
      mood: 'Neutral', 
      context: 'Favor',
      note: note,
      personName: name.trim(), 
      isSettled: false,
    );
    await DataService().repository.saveEntry(newEntry);
    _loadData(); 
  }

  Future<void> _toggleSettle(ReflectionEntry entry) async {
    HapticFeedback.mediumImpact();
    // Toggle Status
    final updated = ReflectionEntry(
      id: entry.id,
      amount: entry.amount,
      currencyCode: entry.currencyCode,
      timestamp: entry.timestamp,
      mood: entry.mood,
      context: entry.context,
      note: entry.note,
      personName: entry.personName,
      isSettled: !entry.isSettled, // TOGGLE
    );
    await DataService().repository.saveEntry(updated);
    _loadData();
  }

  Future<void> _deleteEntry(String id) async {
    HapticFeedback.heavyImpact();
    await DataService().repository.deleteEntry(id);
    _loadData();
  }

  void _showAddDialog({String? prefilledName}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2), 
      builder: (context) => _AddFavorDialog(
        initialName: prefilledName,
        onAdd: _addEntry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFCFE), 
      drawer: CoreDrawer(),
      body: Stack(
        children: [
          // 1. ATMOSPHERIC ORBS
          Positioned(top: -100, left: -50, child: _GlowOrb(color: Color(0xFFE3D5FF), size: 400)),
          Positioned(top: 200, right: -100, child: _GlowOrb(color: Color(0xFFFFD6E7), size: 350)),
          Positioned(bottom: -50, left: -50, child: _GlowOrb(color: Color(0xFFCBF3F0), size: 400)),

          // 2. GLOBAL BLUR
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),

          // 3. CONTENT
          _isLoading 
            ? Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))) 
            : CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                   // APP BAR
                   SliverAppBar(
                     backgroundColor: Colors.transparent,
                     elevation: 0,
                     pinned: true,
                     expandedHeight: 0, 
                     toolbarHeight: 60,
                     centerTitle: true,
                     flexibleSpace: ClipRRect(
                       child: BackdropFilter(
                         filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Reduced blur
                         child: Container(
                           decoration: BoxDecoration(
                             color: Colors.transparent, // Fully transparent
                           ),
                         ),
                       ),
                     ),
                     leading: Builder(
                       builder: (ctx) => IconButton(
                         icon: Container(
                           padding: EdgeInsets.all(8),
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                           child: Icon(Icons.menu_rounded, color: Color(0xFF1A1A1A), size: 20),
                         ),
                         onPressed: () => Scaffold.of(ctx).openDrawer(),
                       ),
                     ),
                     title: Text(
                       "Favors",
                       style: GoogleFonts.plusJakartaSans(
                         color: Color(0xFF1A1A1A),
                         fontWeight: FontWeight.w800,
                         fontSize: 20,
                       ),
                     ),
                   ),

                   // HERO: TOTAL OUTSTANDING
                   SliverPadding(
                     padding: EdgeInsets.fromLTRB(24, 20, 24, 30),
                     sliver: SliverToBoxAdapter(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           Text(
                             "Total Outstanding",
                             style: GoogleFonts.plusJakartaSans(
                               fontSize: 16,
                               fontWeight: FontWeight.w600,
                               color: Color(0xFF1A1A1A).withOpacity(0.6),
                             ),
                           ),
                           SizedBox(height: 8),
                           ShaderMask(
                             shaderCallback: (bounds) => LinearGradient(
                               colors: [Color(0xFFBB86FC), Color(0xFFCF6679)], 
                             ).createShader(bounds),
                             child: Text(
                               "₹${_totalOutstanding.toStringAsFixed(0)}",
                               style: GoogleFonts.plusJakartaSans(
                                 fontSize: 56, 
                                 fontWeight: FontWeight.w800,
                                 color: Colors.white, 
                                 height: 1.0,
                                 letterSpacing: -2,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),

                   // EMPTY STATE
                   if (_groupedDebts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volunteer_activism_rounded, size: 48, color: Color(0xFFE9D5FF)),
                              SizedBox(height: 16),
                              Text("No favors recorded.", style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Color(0xFF1A1A1A).withOpacity(0.4), fontWeight: FontWeight.w600)),
                              SizedBox(height: 100),
                            ],
                          ),
                        ),
                      )
                   else
                   // GROUPED LIST
                   SliverPadding(
                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                     sliver: SliverList(
                       delegate: SliverChildBuilderDelegate(
                         (context, index) {
                           return _PersonGlassCard(
                             data: _groupedDebts[index],
                             onAddMore: () => _showAddDialog(prefilledName: _groupedDebts[index].name),
                             onToggleSettle: _toggleSettle,
                             onDelete: _deleteEntry,
                           );
                         },
                         childCount: _groupedDebts.length,
                       ),
                     ),
                   ),
                   
                   SliverToBoxAdapter(child: SizedBox(height: 100)), 
                ],
              ),
        ],
      ),
      // FAB
      floatingActionButton: UnifiedProButton(
          text: "Add Entry",
          onTap: () => _showAddDialog(),
          gradientColors: [
             Color(0xFFBB86FC).withOpacity(0.6), 
             Color(0xFFCF6679).withOpacity(0.6)
          ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- COMPONENTS ---

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.5),
      ),
    );
  }
}

class _PersonGlassCard extends StatefulWidget {
  final PersonDebt data;
  final VoidCallback onAddMore;
  final Function(ReflectionEntry) onToggleSettle;
  final Function(String) onDelete;

  const _PersonGlassCard({required this.data, required this.onAddMore, required this.onToggleSettle, required this.onDelete});

  @override
  State<_PersonGlassCard> createState() => _PersonGlassCardState();
}

class _PersonGlassCardState extends State<_PersonGlassCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final double debt = widget.data.totalAmount;
    final bool isClear = debt == 0;
    final statusColor = isClear ? Color(0xFF10B981) : Color(0xFFC026D3);

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(color: Color(0xFF7C3AED).withOpacity(0.08), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // HEADER ROW
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                           gradient: LinearGradient(
                             begin: Alignment.topLeft, end: Alignment.bottomRight,
                             colors: isClear 
                               ? [Color(0xFFD1FAE5), Color(0xFFECFDF5)] // Greenish
                               : [Color(0xFFE9D5FF), Color(0xFFF3E8FF)], // Purplish
                           ),
                           shape: BoxShape.circle,
                           border: Border.all(color: Colors.white, width: 2), 
                           boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 10)]
                        ),
                        child: Center(
                          child: isClear 
                             ? Icon(Icons.check_rounded, color: statusColor, size: 24)
                             : Text(
                            widget.data.name.isNotEmpty ? widget.data.name[0].toUpperCase() : "?",
                            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: statusColor),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.data.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A),
                                letterSpacing: -0.5
                              ),
                            ),
                            Text(
                              isClear ? "All Settled" : "${widget.data.entries.where((e)=>!e.isSettled).length} active",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w500, color: isClear ? statusColor : Color(0xFF1A1A1A).withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total
                      if (!isClear)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3E8FF).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE9D5FF)),
                        ),
                        child: Text(
                          "₹${debt.toStringAsFixed(0)}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFC026D3), 
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // EXPANDED BODY
              if (_expanded)
                Container(
                  decoration: BoxDecoration(
                     color: Color(0xFFF9FAFB).withOpacity(0.5), 
                     border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
                  ),
                  child: Column(
                    children: [
                       ...widget.data.entries.map((e) {
                         return _EntryItem(
                           entry: e, 
                           onToggleSettle: () => widget.onToggleSettle(e),
                           onDelete: () => widget.onDelete(e.id),
                         );
                       }),
                       
                       // ADD ACTION
                       InkWell(
                         onTap: widget.onAddMore,
                         child: Container(
                           width: double.infinity,
                           padding: EdgeInsets.symmetric(vertical: 18),
                           alignment: Alignment.center,
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF8B5CF6)),
                               SizedBox(width: 8),
                               Text(
                                 "Add another for ${widget.data.name}",
                                 style: GoogleFonts.plusJakartaSans(
                                   fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6),
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
        ),
      ),
    );
  }
}

class _EntryItem extends StatelessWidget {
  final ReflectionEntry entry;
  final VoidCallback onToggleSettle;
  final VoidCallback onDelete;

  const _EntryItem({required this.entry, required this.onToggleSettle, required this.onDelete});

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Entry Options", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  SizedBox(height: 24),
                  
                  // TOGGLE SETTLE
                  _OptionButton(
                    icon: entry.isSettled ? Icons.undo_rounded : Icons.check_circle_rounded,
                    color: entry.isSettled ? Color(0xFF6366F1) : Color(0xFF10B981),
                    text: entry.isSettled ? "Mark as Unpaid" : "Mark as Returned",
                    onTap: () {
                      Navigator.pop(ctx);
                      onToggleSettle();
                    },
                  ),
                  SizedBox(height: 12),

                  // DELETE
                  _OptionButton(
                    icon: Icons.delete_rounded,
                    color: Color(0xFFEF4444),
                    text: "Delete Entry",
                    isDestructive: true,
                    onTap: () async {
                      Navigator.pop(ctx);
                      // Confirm Delete
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                           title: Text("Delete Generally?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                           content: Text("This will permanently remove the record.", style: GoogleFonts.plusJakartaSans()),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(c, false), child: Text("Cancel", style: TextStyle(color: Colors.grey))),
                             TextButton(onPressed: () => Navigator.pop(c, true), child: Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                           ],
                        )
                      );
                      if (confirm == true) onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Styling for Settled vs Active
    final isSettled = entry.isSettled;
    final contentColor = isSettled ? Color(0xFF1A1A1A).withOpacity(0.4) : Color(0xFF1A1A1A);
    final amountColor = isSettled ? Color(0xFF10B981).withOpacity(0.7) : Color(0xFF1A1A1A).withOpacity(0.7);
    final decor = isSettled ? TextDecoration.lineThrough : null;

    return InkWell(
      onLongPress: () {
        HapticFeedback.lightImpact();
        _showOptionsDialog(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Dot or Check
            Container(
              width: isSettled ? 16 : 8, height: isSettled ? 16 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: isSettled ? Color(0xFF10B981).withOpacity(0.2) : Color(0xFFD946EF).withOpacity(0.4),
              ),
              child: isSettled ? Icon(Icons.check, size: 10, color: Color(0xFF10B981)) : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note.isNotEmpty ? entry.note : "Favor",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: contentColor.withOpacity(isSettled ? 0.6 : 0.8),
                      decoration: decor,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(entry.timestamp),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: contentColor.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            Text(
              "₹${entry.amount.abs().toStringAsFixed(0)}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15, 
                fontWeight: FontWeight.w700, 
                color: amountColor,
                decoration: decor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionButton({required this.icon, required this.color, required this.text, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(16),
       child: Container(
         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
         decoration: BoxDecoration(
           color: isDestructive ? color.withOpacity(0.08) : color.withOpacity(0.08),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: color.withOpacity(0.2)),
         ),
         child: Row(
           children: [
             Icon(icon, color: color, size: 24),
             SizedBox(width: 16),
             Text(
               text,
               style: GoogleFonts.plusJakartaSans(
                 fontSize: 16, 
                 fontWeight: FontWeight.w700,
                 color: isDestructive ? color : Color(0xFF1A1A1A)
               ),
             ),
           ],
         ),
       ),
     );
  }
}

class _AddFavorDialog extends StatefulWidget {
  final String? initialName;
  final Function(String, double, String) onAdd;

  const _AddFavorDialog({this.initialName, required this.onAdd});

  @override
  State<_AddFavorDialog> createState() => _AddFavorDialogState();
}

class _AddFavorDialogState extends State<_AddFavorDialog> {
  late TextEditingController _nameCtrl;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? "");
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final note = _noteCtrl.text.trim();

    if (name.isNotEmpty && amount > 0) {
      widget.onAdd(name, amount, note);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium Glass Dialog
    return Dialog(
       backgroundColor: Colors.transparent,
       insetPadding: EdgeInsets.all(20),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(32),
         child: BackdropFilter(
           filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
           child: Container(
             padding: EdgeInsets.all(32),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.8), // Milk Glass
               borderRadius: BorderRadius.circular(32),
               border: Border.all(color: Colors.white, width: 1),
               boxShadow: [
                 BoxShadow(color: Color(0xFF8B5CF6).withOpacity(0.15), blurRadius: 40, offset: Offset(0, 10)),
               ],
             ),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Center(
                   child: Text("New Favor", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                 ),
                 SizedBox(height: 24),
                 // Name field with Icon
                 _buildField(_nameCtrl, "Who owes you?", Icons.person_outline_rounded),
                 SizedBox(height: 12),
                 // Amount field with Icon
                 _buildField(_amountCtrl, "Amount (₹)", Icons.currency_rupee_rounded, isNumber: true),
                 SizedBox(height: 12),
                 // Note field with Icon
                 _buildField(_noteCtrl, "What for? (Optional)", Icons.note_alt_outlined),
                 SizedBox(height: 32),
                 // Gradient Button (Deep Violet for visual distinction from FAB)
                 UnifiedProButton(
                   text: "Add to List",
                   onTap: _submit,
                   gradientColors: [
                      Color(0xFF8B5CF6), // Violet-500
                      Color(0xFF7C3AED)  // Violet-600
                   ],
                   isWide: true, 
                 ),
               ],
             ),
           ),
         ),
       ),
    );
  }


  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF8B5CF6).withOpacity(0.6), size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        ),
      ),
    );
  }
}
