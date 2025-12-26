import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/data_service.dart';
import '../data/models/reflection_entry.dart';
import '../theme/core_theme.dart';

class DataTransparencyScreen extends StatefulWidget {
  const DataTransparencyScreen({super.key});

  @override
  State<DataTransparencyScreen> createState() => _DataTransparencyScreenState();
}

class _DataTransparencyScreenState extends State<DataTransparencyScreen> {
  late Future<List<ReflectionEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _entriesFuture = DataService().repository.getEntries();
    });
  }

  Future<void> _handleClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will remove all entries from this device.\nThis action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: CoreTheme.deepInk),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DataService().repository.deleteAll();
      // Silent reload. No snackbar.
      _loadData();
    }
  }

  Future<void> _handleCopyJson(List<ReflectionEntry> entries) async {
    // Basic JSON dump for verification
    final jsonString = entries.map((e) => e.toJson()).toString();
    await Clipboard.setData(ClipboardData(text: jsonString));
    // Small toast is acceptable here for technical action feedback, 
    // but per strict rules, let's keep it silent or minimal. 
    // User requested COPY action, so feedback is expected? 
    // Plan says "Copy JSON to Clipboard" action. 
    // "No celebratory feedback after *deletion*". Copying is different.
    // I will show a very neutral SnackBar for Copy Only.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('JSON copied to clipboard.', style: CoreTheme.textTheme.bodyMedium?.copyWith(color: CoreTheme.quietBackground)),
          backgroundColor: CoreTheme.deepInk,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Log', style: Theme.of(context).textTheme.displayMedium),
      ),
      body: FutureBuilder<List<ReflectionEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          
          return Column(
            children: [
              // Control Bar (Functional)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreTheme.spacingWrapper,
                  vertical: CoreTheme.spacingItem,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: entries.isEmpty ? null : () => _handleCopyJson(entries),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CoreTheme.deepInk,
                          side: const BorderSide(color: CoreTheme.softGraphite),
                        ),
                        child: const Text('Copy JSON'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: entries.isEmpty ? null : _handleClearAll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CoreTheme.deepInk, 
                          side: const BorderSide(color: CoreTheme.faintStone),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1), // Subtle hairline
              
              // Log List (Technical Archive)
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1, indent: 16, endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CoreTheme.spacingWrapper,
                        vertical: 8,
                      ),
                      title: Text(
                        'ID: ...${entry.id.substring(entry.id.length - 8)}', // Abstract ID
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Courier', 
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Stored Entry', // No values shown in summary
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
