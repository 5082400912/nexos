// lib/screens/filemanager/file_manager_screen.dart
// FR-03 – File Manager App
//
// Supports: create, save, rename, delete, open files.
// File formats: .txt, .json, .md (3 required types).
// Data is persistent via app-sandboxed storage.
//
// ── Native Android APIs ───────────────────────────────────────────────────
//   android.os.Environment              → getFilesDir(), getExternalStorageDir()
//   java.io.File                        → createNewFile(), delete(), renameTo()
//   android.content.Intent (ACTION_VIEW)→ open file with registered app
//   android.webkit.MimeTypeMap          → MIME type resolution
//   android.provider.MediaStore         → media file registration
//
// Flutter plugins:
//   path_provider  → maps to Context.getFilesDir() / getExternalFilesDir()
//   open_file      → wraps Intent(ACTION_VIEW) for registered MIME handlers
//   file_picker    → wraps Intent(ACTION_GET_CONTENT) for file selection
// ─────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

import '../../theme/nexos_theme.dart';
import '../../widgets/nexos_app_shell.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<FileSystemEntity> _files = [];
  Directory? _appDir;
  bool _loading = true;

  // Supported extensions (3 required formats)
  static const _supportedExts = ['.txt', '.json', '.md'];
  static const _extIcons = {
    '.txt':  Icons.description_outlined,
    '.json': Icons.data_object_rounded,
    '.md':   Icons.article_outlined,
  };
  static const _extColors = {
    '.txt':  Color(0xFF00D4FF),
    '.json': Color(0xFFFFB300),
    '.md':   Color(0xFFE040FB),
  };

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  // ── Android API: Context.getFilesDir() via path_provider ─────────────────
  Future<void> _initDir() async {
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    _appDir = Directory(p.join(dir.path, 'nexos_files'));
    if (!await _appDir!.exists()) await _appDir!.create(recursive: true);
    _refresh();
  }

  Future<void> _refresh() async {
    if (_appDir == null) return;
    final files = _appDir!
        .listSync()
        .whereType<File>()
        .where((f) => _supportedExts.contains(p.extension(f.path)))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    if (mounted) setState(() { _files = files; _loading = false; });
  }

  // ── java.io.File.createNewFile() → create & write ────────────────────────
  Future<void> _createFile(String name, String ext, String content) async {
    if (_appDir == null) return;
    final file = File(p.join(_appDir!.path, '$name$ext'));
    await file.writeAsString(content);
    _refresh();
    _showSnack('File created: $name$ext');
  }

  // ── java.io.File.delete() ─────────────────────────────────────────────────
  Future<void> _deleteFile(File file) async {
    await file.delete();
    _refresh();
    _showSnack('Deleted: ${p.basename(file.path)}');
  }

  // ── java.io.File.renameTo() ───────────────────────────────────────────────
  Future<void> _renameFile(File file, String newName) async {
    final ext = p.extension(file.path);
    final newPath = p.join(_appDir!.path, '$newName$ext');
    await file.rename(newPath);
    _refresh();
    _showSnack('Renamed to: $newName$ext');
  }

  // ── android.content.Intent(ACTION_VIEW) via open_file ────────────────────
  Future<void> _openFile(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      _showSnack('Cannot open file: ${result.message}');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.spaceGrotesk()), backgroundColor: NexOSTheme.surfaceAlt),
    );
  }

  // ── Create file dialog ────────────────────────────────────────────────────
  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedExt = '.txt';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: NexOSTheme.surface,
          title: Text('New File', style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textPri)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: NexOSTheme.textPri),
                decoration: const InputDecoration(labelText: 'File name (no extension)'),
              ),
              const SizedBox(height: 12),
              // Extension picker
              Row(
                children: _supportedExts.map((ext) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(ext, style: GoogleFonts.sourceCodePro(fontSize: 12)),
                    selected: selectedExt == ext,
                    selectedColor: NexOSTheme.accent.withOpacity(0.2),
                    onSelected: (_) => setS(() => selectedExt = ext),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                style: const TextStyle(color: NexOSTheme.textPri),
                decoration: const InputDecoration(labelText: 'Content'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                _createFile(name, selectedExt, contentCtrl.text);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rename dialog ─────────────────────────────────────────────────────────
  void _showRenameDialog(File file) {
    final ctrl = TextEditingController(
      text: p.basenameWithoutExtension(file.path),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NexOSTheme.surface,
        title: Text('Rename File', style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textPri)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: NexOSTheme.textPri),
          decoration: const InputDecoration(labelText: 'New name (no extension)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              _renameFile(file, name);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NexOSAppShell(
      title: 'File Manager',
      icon: Icons.folder_open_rounded,
      iconColor: const Color(0xFFFFB300),
      apiNote: 'java.io.File + path_provider\nMaps to Context.getFilesDir() on Android. File ops use java.io.File methods.',
      fab: FloatingActionButton(
        backgroundColor: const Color(0xFFFFB300),
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: NexOSTheme.bg),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NexOSTheme.accent))
          : _files.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (ctx, i) {
                    final file = _files[i] as File;
                    final ext = p.extension(file.path);
                    final stat = file.statSync();
                    final size = stat.size;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _extIcons[ext] ?? Icons.insert_drive_file,
                          color: _extColors[ext] ?? NexOSTheme.textSec,
                        ),
                        title: Text(p.basename(file.path),
                          style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textPri, fontSize: 14)),
                        subtitle: Text(
                          '${_fmtSize(size)}  •  ${DateFormat('MMM d, HH:mm').format(stat.modified)}',
                          style: GoogleFonts.sourceCodePro(color: NexOSTheme.textSec, fontSize: 11),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: NexOSTheme.surfaceAlt,
                          onSelected: (v) {
                            if (v == 'open') _openFile(file);
                            if (v == 'rename') _showRenameDialog(file);
                            if (v == 'delete') _deleteFile(file);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'open', child: Text('Open')),
                            const PopupMenuItem(value: 'rename', child: Text('Rename')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: NexOSTheme.error)),
                            ),
                          ],
                        ),
                        onTap: () => _openFile(file),
                      ),
                    );
                  },
                ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.folder_open_rounded, color: NexOSTheme.textSec, size: 56),
        const SizedBox(height: 12),
        Text('No files yet', style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textSec)),
        const SizedBox(height: 6),
        Text('Tap + to create a .txt, .json or .md file',
          style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textSec, fontSize: 12)),
      ],
    ),
  );
}
