// lib/screens/camera/camera_screen.dart
// FR-04 – Camera App
//
// Connects to device camera, captures photos and screenshots, saves persistently.
//
// ── Native Android APIs ───────────────────────────────────────────────────
//   android.hardware.camera2.CameraManager   → openCamera(), getCameraIdList()
//   android.hardware.camera2.CameraDevice    → createCaptureSession()
//   android.hardware.camera2.CaptureRequest  → CONTROL_AF_MODE, FLASH_MODE
//   android.media.ImageReader               → acquireLatestImage()
//   android.Manifest.permission.CAMERA      → runtime permission (API 23+)
//   android.os.Environment                  → DIRECTORY_PICTURES path
//   android.provider.MediaStore             → insert image to media library
//
// Flutter plugins:
//   camera        → wraps Camera2 API (CameraController, CameraPreview)
//   image_picker  → wraps Intent(MediaStore.ACTION_IMAGE_CAPTURE)
//   permission_handler → wraps ActivityCompat.requestPermissions()
//   path_provider → getApplicationDocumentsDirectory()
// ─────────────────────────────────────────────────────────────────────────
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../../theme/nexos_theme.dart';
import '../../widgets/nexos_app_shell.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initialized = false;
  bool _permissionDenied = false;
  int _selectedCamera = 0;
  bool _capturing = false;
  String? _lastCapturePath;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  // ── android.Manifest.permission.CAMERA → runtime request ─────────────────
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    // ── CameraManager.getCameraIdList() via Flutter camera plugin ────────
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    await _setupController(_cameras[_selectedCamera]);
  }

  // ── CameraManager.openCamera() + createCaptureSession() ──────────────────
  Future<void> _setupController(CameraDescription cam) async {
    await _controller?.dispose();
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    await _controller!.setFlashMode(_flashMode);
    if (mounted) setState(() => _initialized = true);
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _initialized = false;
      _selectedCamera = 1 - _selectedCamera;
    });
    await _setupController(_cameras[_selectedCamera]);
  }

  void _toggleFlash() async {
    final next = _flashMode == FlashMode.off ? FlashMode.auto : FlashMode.off;
    await _controller?.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  // ── ImageReader.acquireLatestImage() → save to persistent storage ─────────
  Future<void> _capture() async {
    if (_controller == null || !_initialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final xfile = await _controller!.takePicture();

      // Save to public gallery
      // Native Android API: MediaStore.Images.Media.insertImage()
      // Save to public Pictures folder
      // Native Android API: Environment.getExternalStoragePublicDirectory(DIRECTORY_PICTURES)
      final publicDir = Directory('/storage/emulated/0/Pictures/NexOS');
      if (!await publicDir.exists()) {
        await publicDir.create(recursive: true);
      }
      final pubFilename =
          'photo_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.jpg';
      await File(xfile.path).copy('${publicDir.path}/$pubFilename');

      // Also save to app directory for Gallery viewer
      final dir = await _getNexOSImagesDir();
      final filename =
          'photo_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.jpg';
      final path = p.join(dir.path, filename);
      await File(xfile.path).copy(path);

      setState(() {
        _lastCapturePath = path;
        _capturing = false;
      });
      _showSnack('Photo saved to Gallery and NexOS album');
    } catch (e) {
      setState(() => _capturing = false);
      _showSnack('Capture failed: $e');
    }
  }

  // Screenshot: render the camera preview widget to an image buffer
  Future<void> _screenshot() async {
    try {
      final dir = await _getNexOSImagesDir();
      final filename =
          'screenshot_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';
      final path = p.join(dir.path, filename);

      // Capture the full screen using RenderRepaintBoundary
      final boundary =
          _screenshotKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      await File(path).writeAsBytes(byteData.buffer.asUint8List());

      _showSnack('Screenshot saved: $filename');
    } catch (e) {
      _showSnack('Screenshot failed: $e');
    }
  }

  final GlobalKey _screenshotKey = GlobalKey();

  Future<Directory> _getNexOSImagesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'nexos_images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: NexOSTheme.surfaceAlt),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupController(_cameras[_selectedCamera]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NexOSAppShell(
      title: 'Camera',
      icon: Icons.camera_alt_rounded,
      iconColor: const Color(0xFF69F0AE),
      apiNote:
          'android.hardware.camera2.CameraManager\nCameraController wraps Camera2 API. Permission via ActivityCompat.requestPermissions().',
      body: _permissionDenied
          ? _PermissionDenied()
          : !_initialized
          ? const Center(
              child: CircularProgressIndicator(color: NexOSTheme.accent),
            )
          : RepaintBoundary(
              key: _screenshotKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Camera preview ─────────────────────────────
                  ClipRRect(child: CameraPreview(_controller!)),

                  // ── Controls overlay ───────────────────────────
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _ControlsBar(
                      onCapture: _capture,
                      onScreenshot: _screenshot,
                      onSwitchCamera: _cameras.length > 1
                          ? _switchCamera
                          : null,
                      onFlashToggle: _toggleFlash,
                      flashMode: _flashMode,
                      capturing: _capturing,
                      lastCapturePath: _lastCapturePath,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Controls bar ─────────────────────────────────────────────────────────────
class _ControlsBar extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onScreenshot;
  final VoidCallback? onSwitchCamera;
  final VoidCallback onFlashToggle;
  final FlashMode flashMode;
  final bool capturing;
  final String? lastCapturePath;

  const _ControlsBar({
    required this.onCapture,
    required this.onScreenshot,
    required this.onSwitchCamera,
    required this.onFlashToggle,
    required this.flashMode,
    required this.capturing,
    required this.lastCapturePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Last capture thumbnail
          GestureDetector(
            onTap: () {}, // navigate to gallery
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30),
                color: Colors.black38,
                image: lastCapturePath != null
                    ? DecorationImage(
                        image: FileImage(File(lastCapturePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: lastCapturePath == null
                  ? const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white54,
                      size: 20,
                    )
                  : null,
            ),
          ),

          // Shutter
          GestureDetector(
            onTap: capturing ? null : onCapture,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: capturing ? NexOSTheme.textSec : Colors.white,
                border: Border.all(color: Colors.white30, width: 3),
              ),
              child: capturing
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NexOSTheme.accent,
                    )
                  : null,
            ),
          ),

          // Switch / flash / screenshot column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  flashMode == FlashMode.off
                      ? Icons.flash_off
                      : Icons.flash_auto,
                  color: Colors.white,
                ),
                onPressed: onFlashToggle,
              ),
              if (onSwitchCamera != null)
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_android,
                    color: Colors.white,
                  ),
                  onPressed: onSwitchCamera,
                ),
              IconButton(
                icon: const Icon(Icons.screenshot, color: Colors.white),
                onPressed: onScreenshot,
                tooltip: 'Screenshot',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.no_photography, color: NexOSTheme.error, size: 56),
        const SizedBox(height: 12),
        Text(
          'Camera permission denied',
          style: GoogleFonts.spaceGrotesk(color: NexOSTheme.textPri),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: openAppSettings,
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
