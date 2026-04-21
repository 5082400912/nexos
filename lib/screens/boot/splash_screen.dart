// lib/screens/boot/splash_screen.dart
// FR-01 – Boot & Splash Screen
//
// Simulates OS POST → kernel load → user-space init sequence.
// Demonstrates: process initialization, staged loading, system startup UX.
//
// Native Android API used:
//   android.os.Process.myPid()        → process ID of the app process
//   android.app.ActivityManager       → system process management
//   (accessed in Flutter via platform channel – see DeviceService)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/nexos_theme.dart';
import '../desktop/desktop_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  double _progress = 0.0;
  int _bootStepIndex = 0;
  bool _done = false;

  // Simulated POST / kernel init messages – mirrors real Linux dmesg output
  final List<_BootEntry> _bootLog = [
    _BootEntry(0.05,  '[    0.000] NexOS Kernel 5.15.0-nexos initializing...'),
    _BootEntry(0.12,  '[    0.124] BIOS handoff complete. Bootloader active.'),
    _BootEntry(0.20,  '[    0.318] Memory subsystem: 8192MB RAM detected'),
    _BootEntry(0.28,  '[    0.512] CPU scheduler: CFS policy loaded'),
    _BootEntry(0.36,  '[    0.701] VFS: Mounting root filesystem...'),
    _BootEntry(0.44,  '[    0.890] Storage driver: eMMC/UFS device ready'),
    _BootEntry(0.52,  '[    1.102] Camera HAL: CameraService initialized'),
    _BootEntry(0.60,  '[    1.350] I/O Manager: File descriptors registered'),
    _BootEntry(0.68,  '[    1.580] Permission manager: SELinux policies loaded'),
    _BootEntry(0.76,  '[    1.820] Package manager: App sandbox prepared'),
    _BootEntry(0.84,  '[    2.100] Display server: SurfaceFlinger started'),
    _BootEntry(0.92,  '[    2.340] User-space init: Launching desktop shell...'),
    _BootEntry(1.00,  '[    2.600] NexOS ready. Welcome.'),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _runBootSequence();
  }

  Future<void> _runBootSequence() async {
    for (int i = 0; i < _bootLog.length; i++) {
      await Future.delayed(const Duration(milliseconds: 340));
      if (!mounted) return;
      setState(() {
        _progress = _bootLog[i].progress;
        _bootStepIndex = i + 1;
      });
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _done = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => const DesktopScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C001E), Color(0xFF3D1030), Color(0xFF1A000F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                // ── Ubuntu-style logo ─────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      // Circle of dots – Ubuntu logo homage
                      _UbuntuLogo()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            end: 1.04,
                            duration: 1400.ms,
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(height: 28),
                      Text(
                        'NexOS',
                        style: GoogleFonts.ubuntu(
                          fontSize: 38,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'CSEC 431-1  |  Operating Systems & Analysis',
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          color: NexOSTheme.textSec,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Boot log ──────────────────────────────────────────
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: NexOSTheme.border.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _bootStepIndex,
                    itemBuilder: (ctx, i) {
                      final idx = _bootStepIndex - 1 - i;
                      final entry = _bootLog[idx];
                      final isLast = i == 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          entry.message,
                          style: GoogleFonts.ubuntuMono(
                            fontSize: 11,
                            color: isLast
                                ? NexOSTheme.accent
                                : NexOSTheme.textSec.withValues(alpha: 0.65),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Ubuntu-style dot progress ─────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: _progress),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, val, _) => LinearProgressIndicator(
                            value: val,
                            minHeight: 4,
                            backgroundColor:
                                NexOSTheme.border.withValues(alpha: 0.4),
                            valueColor: const AlwaysStoppedAnimation(
                                NexOSTheme.accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: GoogleFonts.ubuntuMono(
                        color: NexOSTheme.accent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  _done ? 'System ready.' : 'Loading system components...',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: NexOSTheme.textSec,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ubuntu logo circle-of-dots widget ────────────────────────────────────────
class _UbuntuLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88, height: 88,
      child: CustomPaint(painter: _UbuntuLogoPainter()),
    );
  }
}

class _UbuntuLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Outer circle (ring)
    final ringPaint = Paint()
      ..color = NexOSTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(Offset(cx, cy), r - 4, ringPaint);

    // Three dots on the ring (Ubuntu logo positions)
    final dotPaint = Paint()
      ..color = NexOSTheme.accent
      ..style = PaintingStyle.fill;

    const dotR = 9.0;
    const gapAngle = 0.42; // radians gap around each dot

    final dotAngles = [
      -1.5708,          // top
      -1.5708 + 2.094,  // bottom-right
      -1.5708 + 4.189,  // bottom-left
    ];

    final ringR = r - 4;
    for (final angle in dotAngles) {
      // Draw gap (clear the ring)
      final gapPaint = Paint()
        ..color = const Color(0xFF2C001E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: ringR),
        angle - gapAngle / 2,
        gapAngle,
        false,
        gapPaint,
      );
      // Draw dot
      final dx = cx + ringR * _cos(angle);
      final dy = cy + ringR * _sin(angle);
      canvas.drawCircle(Offset(dx, dy), dotR, dotPaint);
    }
  }

  double _cos(double a) => (a == -1.5708) ? 0 : (a < 0 ? 0.866 : -0.866);
  double _sin(double a) {
    if (a == -1.5708) return -1;
    if (a < 0) return 0.5;
    return 0.5;
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BootEntry {
  final double progress;
  final String message;
  const _BootEntry(this.progress, this.message);
}
