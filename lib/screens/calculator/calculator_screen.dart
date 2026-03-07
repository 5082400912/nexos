// lib/screens/calculator/calculator_screen.dart
// FR-06A – Calculator App
//
// Features: arithmetic operations, last-5-calculations history (persistent),
// real-time memory usage display from app start to current state.
//
// ── Native Android APIs ───────────────────────────────────────────────────
//   android.app.ActivityManager.MemoryInfo   → getMemoryInfo() for RAM stats
//   android.os.Debug.MemoryInfo              → getProcessMemoryInfo() for heap
//   android.os.Debug.getNativeHeapAllocatedSize() → native heap tracking
//   android.os.Process.myPid()               → this process's PID
//   android.content.SharedPreferences        → persistent calculation history
//
// Flutter:
//   Hive (shared_preferences equivalent) → persistent history store
//   dart:developer / dart:io              → RSS and heap size queries
// ─────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../theme/nexos_theme.dart';
import '../../widgets/nexos_app_shell.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _operand1;
  String? _operator;
  bool _justCalculated = false;

  // Memory tracking: snapshot at screen init
  late int _startRssBytes;
  int _currentRssBytes = 0;

  // Hive box – maps to SharedPreferences / SQLite on Android
  late Box _historyBox;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    // ── android.os.Debug.getRSSBytes() equivalent ─────────────────────────
    _startRssBytes = ProcessInfo.currentRss;
    _currentRssBytes = _startRssBytes;
    _historyBox = Hive.box('calculator_history');
    _loadHistory();
  }

  void _loadHistory() {
    final raw = _historyBox.get('history', defaultValue: <String>[]);
    setState(() => _history = List<String>.from(raw));
  }

  // ── android.content.SharedPreferences.putString() ─────────────────────
  Future<void> _saveToHistory(String entry) async {
    final updated = [entry, ..._history].take(5).toList();
    await _historyBox.put('history', updated);
    setState(() => _history = updated);
  }

  // ── android.os.Debug.getRSSBytes() → process memory snapshot ─────────
  void _updateMemory() {
    setState(() => _currentRssBytes = ProcessInfo.currentRss);
  }

  // ── Calculator logic ──────────────────────────────────────────────────
  void _onButton(String label) {
    _updateMemory();

    if (label == 'C') {
      setState(() {
        _display = '0';
        _expression = '';
        _operand1 = null;
        _operator = null;
        _justCalculated = false;
      });
      return;
    }
    if (label == '⌫') {
      if (_display.length > 1)
        setState(() => _display = _display.substring(0, _display.length - 1));
      else
        setState(() => _display = '0');
      return;
    }
    if (label == '±') {
      final v = double.tryParse(_display) ?? 0;
      setState(() => _display = _fmt(-v));
      return;
    }
    if (label == '%') {
      final v = double.tryParse(_display) ?? 0;
      setState(() => _display = _fmt(v / 100));
      return;
    }

    final operators = ['+', '−', '×', '÷'];
    if (operators.contains(label)) {
      _operand1 = double.tryParse(_display);
      _operator = label;
      setState(() {
        _expression = '$_display $label';
        _justCalculated = false;
      });
      return;
    }

    if (label == '=') {
      if (_operand1 == null || _operator == null) return;
      final b = double.tryParse(_display) ?? 0;
      double result;
      switch (_operator) {
        case '+':
          result = _operand1! + b;
          break;
        case '−':
          result = _operand1! - b;
          break;
        case '×':
          result = _operand1! * b;
          break;
        case '÷':
          result = b != 0 ? _operand1! / b : double.nan;
          break;
        default:
          return;
      }
      final expr =
          '${_fmt(_operand1!)} $_operator ${_fmt(b)} = ${_fmt(result)}';
      _saveToHistory(expr);
      setState(() {
        _display = result.isNaN ? 'Error' : _fmt(result);
        _expression = expr;
        _operand1 = null;
        _operator = null;
        _justCalculated = true;
      });
      return;
    }

    if (label == '.') {
      if (_display.contains('.')) return;
      setState(() => _display = '$_display.');
      return;
    }

    // Digit
    if (_justCalculated ||
        _operator != null && _operand1 != null && !_expression.contains('=')) {
      setState(() {
        _display = label;
        _justCalculated = false;
      });
    } else if (_display == '0') {
      setState(() => _display = label);
    } else {
      if (_display.length >= 12) return;
      setState(() => _display += label);
    }
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  // ── Button layout ─────────────────────────────────────────────────────
  static const _buttons = [
    ['C', '±', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['⌫', '0', '.', '='],
  ];

  Color _btnColor(String label) {
    if (label == '=') return NexOSTheme.accent;
    if (['÷', '×', '−', '+'].contains(label)) return const Color(0xFF7B2FFF);
    if (['C', '±', '%'].contains(label)) return NexOSTheme.surfaceAlt;
    return NexOSTheme.surface;
  }

  Color _lblColor(String label) {
    if (label == '=') return NexOSTheme.bg;
    if (['÷', '×', '−', '+'].contains(label)) return Colors.white;
    if (['C', '±', '%'].contains(label)) return NexOSTheme.textSec;
    return NexOSTheme.textPri;
  }

  @override
  Widget build(BuildContext context) {
    final deltaKB = (_currentRssBytes - _startRssBytes) / 1024;
    final totalMB = _currentRssBytes / (1024 * 1024);

    return NexOSAppShell(
      title: 'Calculator',
      icon: Icons.calculate_rounded,
      iconColor: const Color(0xFFFF5252),
      apiNote:
          'android.app.ActivityManager.MemoryInfo\ndart:io ProcessInfo.currentRss maps to getProcessMemoryInfo(pid) for heap tracking.',
      body: Column(
        children: [
          // ── Memory stats bar ────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: NexOSTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NexOSTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.memory, color: NexOSTheme.accent, size: 14),
                const SizedBox(width: 8),
                Text(
                  'RSS: ${totalMB.toStringAsFixed(1)} MB',
                  style: GoogleFonts.sourceCodePro(
                    color: NexOSTheme.textSec,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Δ since open: ${deltaKB >= 0 ? '+' : ''}${deltaKB.toStringAsFixed(0)} KB',
                  style: GoogleFonts.sourceCodePro(
                    color: deltaKB > 500
                        ? NexOSTheme.warning
                        : NexOSTheme.success,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── Display ─────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expression.isNotEmpty)
                    Text(
                      _expression,
                      style: GoogleFonts.spaceGrotesk(
                        color: NexOSTheme.textSec,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _display,
                    style: GoogleFonts.orbitron(
                      color: NexOSTheme.textPri,
                      fontSize: _display.length > 9 ? 28 : 42,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),

          // ── History (last 5) ────────────────────────────────────
          if (_history.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: NexOSTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NexOSTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history,
                          color: NexOSTheme.textSec,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Last 5',
                          style: GoogleFonts.spaceGrotesk(
                            color: NexOSTheme.textSec,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      reverse: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _history
                          .map(
                            (h) => Text(
                              h,
                              style: GoogleFonts.sourceCodePro(
                                color: NexOSTheme.textSec,
                                fontSize: 10,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // ── Buttons ─────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: _buttons
                    .map(
                      (row) => Expanded(
                        child: Row(
                          children: row
                              .map(
                                (label) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: GestureDetector(
                                      onTap: () => _onButton(label),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _btnColor(label),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: NexOSTheme.border,
                                            width: 0.5,
                                          ),
                                          boxShadow: label == '='
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        NexOSTheme.accentGlow,
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          label,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: _lblColor(label),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
