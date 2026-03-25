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
      color: const Color(0xFF729FCF),
      screen: const AboutScreen(),
    ),
    _AppTile(
      label: 'File Manager',
      icon: Icons.folder_open_rounded,
      color: const Color(0xFFE95420),
      screen: const FileManagerScreen(),
    ),
    _AppTile(
      label: 'Camera',
      icon: Icons.camera_alt_rounded,
      color: const Color(0xFF8AE234),
      screen: const CameraScreen(),
    ),
    _AppTile(
      label: 'Gallery',
      icon: Icons.photo_library_rounded,
      color: const Color(0xFFAD7FA8),
      screen: const GalleryScreen(),
    ),
    _AppTile(
      label: 'Calculator',
      icon: Icons.calculate_rounded,
      color: const Color(0xFFFCE94F),
      screen: const CalculatorScreen(),
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
            // ── GNOME-style top panel ──────────────────────────────────
            _TopPanel(clock: _clock),

            // ── Wallpaper area + App grid ──────────────────────────────
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Section label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Applications',
                          style: GoogleFonts.ubuntu(
                            color: NexOSTheme.textSec,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // App grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
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
                ],
              ),
            ),

            // ── Ubuntu-style dock ──────────────────────────────────────
            _Dock(apps: _apps, onLaunch: _launch),
          ],
        ),
      ),
    );
  }
}

// ── GNOME top panel ──────────────────────────────────────────────────────────
class _TopPanel extends StatelessWidget {
  final Stream<DateTime> clock;
  const _TopPanel({required this.clock});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0014),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Activities button (left)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: NexOSTheme.accent.withValues(alpha: 0.15),
            ),
            child: Text(
              'Activities',
              style: GoogleFonts.ubuntu(
                color: NexOSTheme.textPri,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Clock (center)
          Expanded(
            child: StreamBuilder<DateTime>(
              stream: clock,
              initialData: DateTime.now(),
              builder: (_, snap) => Center(
                child: Text(
                  DateFormat('EEE MMM d  HH:mm').format(snap.data!),
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    color: NexOSTheme.textPri,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),

          // System tray (right)
          Row(
            children: [
              const Icon(Icons.wifi, size: 15, color: NexOSTheme.textPri),
              const SizedBox(width: 6),
              const Icon(Icons.volume_up_outlined, size: 15, color: NexOSTheme.textPri),
              const SizedBox(width: 6),
              const Icon(Icons.battery_std_outlined, size: 15, color: NexOSTheme.textPri),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 16, color: NexOSTheme.textSec),
            ],
          ),
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
            width: 68, height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tile.color.withValues(alpha: 0.9),
                  tile.color.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: tile.color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(tile.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            tile.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.ubuntu(
              fontSize: 11,
              color: NexOSTheme.textPri,
              fontWeight: FontWeight.w400,
              shadows: [
                const Shadow(color: Colors.black54, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ubuntu-style bottom dock ─────────────────────────────────────────────────
class _Dock extends StatelessWidget {
  final List<_AppTile> apps;
  final void Function(BuildContext, Widget) onLaunch;

  const _Dock({required this.apps, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0014).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexOSTheme.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home dot indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: NexOSTheme.accent, size: 6),
              const SizedBox(height: 4),
              Icon(Icons.home_rounded, color: NexOSTheme.accent, size: 22),
            ],
          ),

          Container(width: 1, height: 32, color: NexOSTheme.border),

          // App shortcuts in dock
          ...apps.take(4).map((app) => GestureDetector(
            onTap: () => onLaunch(context, app.screen),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: app.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: app.color.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(app.icon, color: app.color, size: 20),
            ),
          )),
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
  const _AppTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
