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
        backgroundColor: const Color(0xFF1A0014),
        elevation: 0,
        leading: const BackButton(color: NexOSTheme.textPri),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.ubuntu(
                color: NexOSTheme.textPri,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal,
                color: NexOSTheme.textSec, size: 20),
            tooltip: 'API reference',
            onPressed: () => _showApiNote(context),
          ),
          ...?actions,
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: NexOSTheme.border),
        ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                Text(
                  'Native Android API Reference',
                  style: GoogleFonts.ubuntu(
                    color: NexOSTheme.textPri,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: NexOSTheme.border),
              ),
              child: Text(
                apiNote,
                style: GoogleFonts.ubuntuMono(
                  color: NexOSTheme.accent,
                  fontSize: 12,
                  height: 1.7,
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
