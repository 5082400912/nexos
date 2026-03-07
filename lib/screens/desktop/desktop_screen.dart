// lib/screens/desktop/desktop_screen.dart
// FR-01 – Desktop Shell (home screen after login)
//
// Simulates: window manager / launcher in Android (android.app.LauncherActivity)
// Each app tile dispatches a named route equivalent to launching an Intent.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../theme/nexos_theme.dart';
import '../about/about_screen.dart';
import '../filemanager/file_manager_screen.dart';
import '../camera/camera_screen.dart';
import '../gallery/gallery_screen.dart';
import '../calculator/calculator_screen.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  late final Stream<DateTime> _clock;

  @override
  void initState() {
    super.initState();
    _clock = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  // App manifest – analogous to Android LauncherApps listing installed packages
  final List<_AppTile> _apps = [
    _AppTile(
      label: 'About Device',
      icon: Icons.info_outline_rounded,
      color: const Color(0xFF00D4FF),
      screen: const AboutScreen(),
      description: 'System & hardware info',
    ),
    _AppTile(
      label: 'File Manager',
      icon: Icons.folder_open_rounded,
      color: const Color(0xFFFFB300),
      screen: const FileManagerScreen(),
      description: 'Browse & manage files',
    ),
    _AppTile(
      label: 'Camera',
      icon: Icons.camera_alt_rounded,
      color: const Color(0xFF69F0AE),
      screen: const CameraScreen(),
      description: 'Capture photos & screenshots',
    ),
    _AppTile(
      label: 'Gallery',
      icon: Icons.photo_library_rounded,
      color: const Color(0xFFE040FB),
      screen: const GalleryScreen(),
      description: 'View saved images',
    ),
    _AppTile(
      label: 'Calculator',
      icon: Icons.calculate_rounded,
      color: const Color(0xFFFF5252),
      screen: const CalculatorScreen(),
      description: 'Compute with memory tracking',
    ),
  ];

  void _launch(BuildContext ctx, Widget screen) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexOSTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Status Bar ─────────────────────────────────────────────
            _StatusBar(clock: _clock),

            // ── Wallpaper header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.memory, color: NexOSTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('NexOS Desktop',
                    style: GoogleFonts.orbitron(
                      color: NexOSTheme.accent, fontSize: 16, fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: NexOSTheme.border, height: 1),
            ),

            const SizedBox(height: 12),

            // ── App grid ───────────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _apps.length,
                itemBuilder: (ctx, i) => _AppIcon(
                  tile: _apps[i],
                  onTap: () => _launch(ctx, _apps[i].screen),
                ),
              ),
            ),

            // ── Taskbar ────────────────────────────────────────────────
            _Taskbar(),
          ],
        ),
      ),
    );
  }
}

// ── Status bar ──────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final Stream<DateTime> clock;
  const _StatusBar({required this.clock});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NexOSTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<DateTime>(
            stream: clock,
            initialData: DateTime.now(),
            builder: (_, snap) => Text(
              DateFormat('HH:mm  EEE, MMM d').format(snap.data!),
              style: GoogleFonts.sourceCodePro(
                fontSize: 12, color: NexOSTheme.textPri, fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          const Icon(Icons.wifi, size: 16, color: NexOSTheme.textSec),
          const SizedBox(width: 8),
          const Icon(Icons.signal_cellular_alt, size: 16, color: NexOSTheme.textSec),
          const SizedBox(width: 8),
          const Icon(Icons.battery_std, size: 16, color: NexOSTheme.success),
        ],
      ),
    );
  }
}

// ── Individual app icon ──────────────────────────────────────────────────────
class _AppIcon extends StatelessWidget {
  final _AppTile tile;
  final VoidCallback onTap;
  const _AppIcon({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: tile.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tile.color.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(color: tile.color.withOpacity(0.15), blurRadius: 12, spreadRadius: 1),
              ],
            ),
            child: Icon(tile.icon, color: tile.color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(tile.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11, color: NexOSTheme.textPri, fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom taskbar ───────────────────────────────────────────────────────────
class _Taskbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: NexOSTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NexOSTheme.border),
        boxShadow: [BoxShadow(color: NexOSTheme.accentGlow, blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home_rounded, color: NexOSTheme.accent, size: 24),
          Icon(Icons.grid_view_rounded, color: NexOSTheme.textSec, size: 22),
          Icon(Icons.settings_outlined, color: NexOSTheme.textSec, size: 22),
        ],
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────
class _AppTile {
  final String label;
  final IconData icon;
  final Color color;
  final Widget screen;
  final String description;
  const _AppTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.screen,
    required this.description,
  });
}
