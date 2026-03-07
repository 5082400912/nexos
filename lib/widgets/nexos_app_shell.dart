// lib/widgets/nexos_app_shell.dart
// Shared scaffold wrapper for all NexOS mini-apps.
// Provides consistent AppBar, API reference banner, and optional FAB.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/nexos_theme.dart';

class NexOSAppShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String apiNote;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;

  const NexOSAppShell({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.apiNote,
    required this.body,
    this.fab,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexOSTheme.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        leading: const BackButton(),
        actions: [
          // Tap the code icon to see the API reference note
          IconButton(
            icon: const Icon(Icons.terminal, color: NexOSTheme.textSec, size: 20),
            tooltip: 'API reference',
            onPressed: () => _showApiNote(context),
          ),
          ...?actions,
        ],
      ),
      body: body,
      floatingActionButton: fab,
    );
  }

  void _showApiNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexOSTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.code, color: NexOSTheme.accent, size: 18),
                const SizedBox(width: 8),
                Text('Native Android API Reference',
                  style: GoogleFonts.spaceGrotesk(
                    color: NexOSTheme.textPri, fontWeight: FontWeight.w700, fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF060A10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NexOSTheme.border),
              ),
              child: Text(apiNote,
                style: GoogleFonts.sourceCodePro(
                  color: NexOSTheme.accent, fontSize: 12, height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
