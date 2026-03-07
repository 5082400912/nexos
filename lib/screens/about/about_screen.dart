// lib/screens/about/about_screen.dart
// FR-02 – About Device App
//
// Displays hardware and OS information retrieved via native Android APIs.
//
// ── Native Android APIs ───────────────────────────────────────────────────
//   android.os.Build                  → model, brand, board, hardware, ABIs
//   android.os.Build.VERSION          → release, sdkInt, securityPatch
//   android.app.ActivityManager       → MemoryInfo (totalMem, availMem)
//   android.os.Environment            → getExternalStorageDirectory()
//   android.os.StatFs                 → getTotalBytes(), getFreeBytes()
//   android.content.pm.PackageManager → getPackageInfo(), hasSystemFeature()
//
// Flutter plugin: device_info_plus (wraps android.os.Build)
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/nexos_theme.dart';
import '../../services/device_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Map<String, String> _info = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DeviceService.instance.getAndroidInfo();
    if (mounted) setState(() { _info = data; _loading = false; });
  }

  // Grouped sections for display
  Map<String, List<String>> get _sections => {
    'Device Identity': ['Device Name', 'Brand', 'Model', 'Manufacturer', 'Product'],
    'Hardware': ['Hardware', 'Board', 'Supported ABIs', 'Is Physical'],
    'Operating System': ['Android Version', 'API Level', 'Security Patch', 'Build ID'],
    'Build Info': ['Host', 'Fingerprint'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexOSTheme.bg,
      appBar: AppBar(
        title: const Text('About Device'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NexOSTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Device hero card ─────────────────────────────────
                _HeroCard(info: _info),
                const SizedBox(height: 16),

                // ── API reference note ───────────────────────────────
                _ApiNote(
                  api: 'android.os.Build + device_info_plus',
                  detail: 'Reads CPU, model, brand and OS metadata from the Android Build system class at startup.',
                ),
                const SizedBox(height: 16),

                // ── Info sections ────────────────────────────────────
                for (final section in _sections.entries) ...[
                  _SectionHeader(title: section.key),
                  Card(
                    child: Column(
                      children: section.value
                          .where((k) => _info.containsKey(k))
                          .map((k) => _InfoRow(label: k, value: _info[k]!))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

// ── Hero card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final Map<String, String> info;
  const _HeroCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4FF22), Color(0xFF7B2FFF22)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexOSTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NexOSTheme.accentGlow,
              border: Border.all(color: NexOSTheme.accent, width: 1.5),
            ),
            child: const Icon(Icons.smartphone, color: NexOSTheme.accent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info['Brand'] ?? ''} ${info['Model'] ?? 'Device'}',
                  style: GoogleFonts.spaceGrotesk(
                    color: NexOSTheme.textPri, fontSize: 18, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Android ${info['Android Version'] ?? ''} (API ${info['API Level'] ?? ''})',
                  style: GoogleFonts.sourceCodePro(color: NexOSTheme.accent, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(title.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        color: NexOSTheme.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: NexOSTheme.border, width: 0.5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: GoogleFonts.spaceGrotesk(
            color: NexOSTheme.textSec, fontSize: 12,
          )),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.sourceCodePro(
            color: NexOSTheme.textPri, fontSize: 12,
          )),
        ),
      ],
    ),
  );
}

class _ApiNote extends StatelessWidget {
  final String api, detail;
  const _ApiNote({required this.api, required this.detail});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF00D4FF0A),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: NexOSTheme.accent.withOpacity(0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.code, color: NexOSTheme.accent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(api, style: GoogleFonts.sourceCodePro(
                color: NexOSTheme.accent, fontSize: 11, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 2),
              Text(detail, style: GoogleFonts.spaceGrotesk(
                color: NexOSTheme.textSec, fontSize: 11,
              )),
            ],
          ),
        ),
      ],
    ),
  );
}
