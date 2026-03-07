// lib/screens/gallery/gallery_screen.dart
// FR-05 – Gallery Viewer App
//
// Displays all images stored in the NexOS images directory (persistent).
//
// ── Native Android APIs ───────────────────────────────────────────────────
//   android.provider.MediaStore.Images   → query device media library
//   android.content.ContentResolver      → query(), openInputStream()
//   java.io.File                         → read image files from app storage
//   android.Manifest.permission.READ_EXTERNAL_STORAGE → runtime permission
//
// Flutter plugins:
//   path_provider  → getApplicationDocumentsDirectory()
//   photo_view     → zoomable image viewer widget
// ─────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/intl.dart';

import '../../theme/nexos_theme.dart';
import '../../widgets/nexos_app_shell.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> _images = [];
  bool _loading = true;

  static const _imgExts = ['.jpg', '.jpeg', '.png', '.webp'];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // ── java.io.File directory read → ContentResolver equivalent ─────────────
  Future<void> _loadImages() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'nexos_images'));
    if (!await dir.exists()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _imgExts.contains(p.extension(f.path).toLowerCase()))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    if (mounted) setState(() { _images = files; _loading = false; });
  }

  void _openViewer(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ImageViewer(images: _images, initialIndex: index),
    ));
  }

  Future<void> _deleteImage(File file) async {
    await file.delete();
    _loadImages();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted: ${p.basename(file.path)}'),
        backgroundColor: NexOSTheme.surfaceAlt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NexOSAppShell(
      title: 'Gallery',
      icon: Icons.photo_library_rounded,
      iconColor: const Color(0xFFE040FB),
      apiNote: 'android.provider.MediaStore + java.io.File\nReads image files from app-sandboxed storage directory.',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NexOSTheme.accent))
          : _images.isEmpty
              ? _EmptyGallery()
              : RefreshIndicator(
                  onRefresh: _loadImages,
                  color: NexOSTheme.accent,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (ctx, i) {
                      final file = _images[i];
                      return GestureDetector(
                        onTap: () => _openViewer(i),
                        onLongPress: () => _confirmDelete(file),
                        child: Hero(
                          tag: file.path,
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(color: NexOSTheme.border.withOpacity(0.5)),
                            ),
                            // Filename badge
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              color: Colors.black54,
                              child: Text(
                                p.extension(file.path).toUpperCase().replaceAll('.', ''),
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 9, color: NexOSTheme.textSec,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _confirmDelete(File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NexOSTheme.surface,
        title: Text('Delete image?', style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textPri)),
        content: Text(p.basename(file.path), style: GoogleFonts.sourceCodePro(color: NexOSTheme.textSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _deleteImage(file); },
            child: Text('Delete', style: TextStyle(color: NexOSTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen image viewer ─────────────────────────────────────────────────
class _ImageViewer extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  const _ImageViewer({required this.images, required this.initialIndex});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late int _current;
  late PageController _page;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _page = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.images[_current];
    final stat = file.statSync();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(p.basename(file.path),
          style: GoogleFonts.sourceCodePro(fontSize: 13)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_current + 1} / ${widget.images.length}',
                style: GoogleFonts.sourceCodePro(color: NexOSTheme.textSec, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PhotoViewGallery.builder(
              pageController: _page,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              builder: (ctx, i) => PhotoViewGalleryPageOptions(
                imageProvider: FileImage(widget.images[i]),
                heroAttributes: PhotoViewHeroAttributes(tag: widget.images[i].path),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              ),
            ),
          ),
          // Metadata strip
          Container(
            color: const Color(0xFF0A0E1A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: NexOSTheme.textSec, size: 14),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM d yyyy HH:mm').format(stat.modified)}  •  ${_fmtSize(stat.size)}',
                  style: GoogleFonts.sourceCodePro(color: NexOSTheme.textSec, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _EmptyGallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.photo_library_outlined, color: NexOSTheme.textSec, size: 56),
        const SizedBox(height: 12),
        Text('No images yet', style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textSec)),
        const SizedBox(height: 6),
        Text('Take a photo in the Camera app', style: GoogleFonts.spaceGrotesk(
          color: NexOSTheme.textSec, fontSize: 12)),
      ],
    ),
  );
}
