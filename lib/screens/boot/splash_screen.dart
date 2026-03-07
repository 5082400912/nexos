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
import '../login/login_screen.dart';

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
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
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
      backgroundColor: NexOSTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // ── Logo ───────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: NexOSTheme.accent, width: 2),
                        boxShadow: [BoxShadow(color: NexOSTheme.accentGlow, blurRadius: 24, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.memory, color: NexOSTheme.accent, size: 38),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(end: 1.06, duration: 1200.ms, curve: Curves.easeInOut),
                    const SizedBox(height: 20),
                    Text('NexOS',
                      style: GoogleFonts.orbitron(
                        fontSize: 36, fontWeight: FontWeight.w800,
                        color: NexOSTheme.accent,
                        letterSpacing: 6,
                        shadows: [Shadow(color: NexOSTheme.accentGlow, blurRadius: 20)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('CSEC 431-1 | Operating Systems & Analysis',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, color: NexOSTheme.textSec, letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Boot log terminal ──────────────────────────────────────
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF060A10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NexOSTheme.border),
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
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: isLast
                              ? NexOSTheme.accent
                              : NexOSTheme.textSec.withOpacity(0.7),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Progress bar ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: _progress),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, val, __) => LinearProgressIndicator(
                          value: val,
                          minHeight: 6,
                          backgroundColor: NexOSTheme.border,
                          valueColor: const AlwaysStoppedAnimation(NexOSTheme.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: GoogleFonts.sourceCodePro(
                      color: NexOSTheme.accent, fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                _done ? 'System ready.' : 'Loading system components...',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11, color: NexOSTheme.textSec,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootEntry {
  final double progress;
  final String message;
  const _BootEntry(this.progress, this.message);
}
