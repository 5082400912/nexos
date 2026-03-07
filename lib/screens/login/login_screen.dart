// lib/screens/login/login_screen.dart
// FR-01 – Login Gate (simulates OS user authentication before desktop)
//
// Native Android API context:
//   android.hardware.biometrics.BiometricManager  → biometric auth (optional)
//   android.accounts.AccountManager               → registered accounts
//   Simulated here with PIN; BiometricPrompt integration marked for extension.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../theme/nexos_theme.dart';
import '../desktop/desktop_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String _error = '';
  bool _shake = false;

  // Default PIN (in production would use Android Keystore-backed credential)
  static const String _correctPin = '1234';

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = '';
    });
    if (_pin.length == 4) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_pin == _correctPin) {
      // Persist login state via Hive (maps to SharedPreferences / SQLite on Android)
      final box = Hive.box('nexos_prefs');
      await box.put('last_login', DateTime.now().toIso8601String());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const DesktopScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _error = 'Incorrect PIN. Try again.';
        _pin = '';
        _shake = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _shake = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexOSTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Avatar ────────────────────────────────────────────
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NexOSTheme.surfaceAlt,
                    border: Border.all(color: NexOSTheme.accent, width: 2),
                  ),
                  child: const Icon(Icons.person, color: NexOSTheme.accent, size: 36),
                ),
                const SizedBox(height: 16),
                Text('NexOS User', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Enter PIN to unlock', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                // ── PIN dots ──────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: _shake
                      ? Matrix4.translationValues(8, 0, 0)
                      : Matrix4.identity(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? NexOSTheme.accent : Colors.transparent,
                          border: Border.all(
                            color: filled ? NexOSTheme.accent : NexOSTheme.textSec,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _error.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Text(_error,
                    style: GoogleFonts.spaceGrotesk(color: NexOSTheme.error, fontSize: 13)),
                ),
                const SizedBox(height: 24),

                // ── Numpad ────────────────────────────────────────────
                _Numpad(onKey: _onKey, onDelete: _onDelete),

                const SizedBox(height: 24),
                Text('Default PIN: 1234',
                  style: GoogleFonts.sourceCodePro(
                    color: NexOSTheme.textSec.withOpacity(0.4), fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const _Numpad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','⌫'],
    ];
    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 80, height: 60);
            return GestureDetector(
              onTap: () => k == '⌫' ? onDelete() : onKey(k),
              child: Container(
                width: 80, height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: NexOSTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NexOSTheme.border),
                ),
                alignment: Alignment.center,
                child: Text(k,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: k == '⌫' ? 20 : 22,
                    fontWeight: FontWeight.w600,
                    color: k == '⌫' ? NexOSTheme.textSec : NexOSTheme.textPri,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }
}
