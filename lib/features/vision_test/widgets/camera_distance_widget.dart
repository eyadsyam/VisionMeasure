import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/l10n/app_translations.dart';

/// Distance status for UI feedback.
enum DistanceStatus { ok, tooClose, tooFar, noFace, unknown }

class CameraDistanceWidget extends StatefulWidget {
  final ValueChanged<double?> onDistanceChanged;
  final double minCm;
  final double maxCm;

  const CameraDistanceWidget({
    super.key,
    required this.onDistanceChanged,
    this.minCm = 40,
    this.maxCm = 65,
  });

  @override
  State<CameraDistanceWidget> createState() => _CameraDistanceWidgetState();
}

class _CameraDistanceWidgetState extends State<CameraDistanceWidget>
    with WidgetsBindingObserver {
  CameraController? _camera;
  FaceDetector? _detector;
  bool _busy = false;
  bool _initializing = true;
  String? _error;
  double? _distanceCm;
  double? _manualCm;
  bool _useManual = false;
  int _noFaceFrameCount = 0;

  // Reference: average human face width ≈ 14 cm.
  static const double _knownFaceWidthCm = 14.0;

  // EMA smoothing factor (0 < α ≤ 1) — smaller = smoother but slower
  static const double _emaAlpha = 0.25;
  double? _smoothedDistance;

  // Focal length in pixels — computed from camera resolution
  double _focalPx = 500.0;

  // Frame skip to avoid overloading — process every Nth frame
  int _frameCount = 0;
  static const int _frameSkip = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.stopImageStream().catchError((_) {});
    _camera?.dispose();
    _detector?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _fallbackToManual('permission');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fallbackToManual('no_camera');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await controller.initialize();

      final previewSize = controller.value.previewSize;
      if (previewSize != null) {
        // Adaptive focal length: focal = (width/2) / tan(35°) ≈ width * 0.714
        _focalPx = previewSize.width.toInt() * 0.714;
      }

      _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true,
          enableClassification: false,
          minFaceSize: 0.05, // Detect much smaller faces for all ages
        ),
      );

      await controller.startImageStream(_processFrame);

      if (!mounted) return;
      setState(() {
        _camera = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      _fallbackToManual('error');
    }
  }

  void _fallbackToManual(String errorType) {
    if (!mounted) return;
    setState(() {
      _error = errorType;
      _initializing = false;
      _useManual = true;
      _manualCm = 50;
    });
    widget.onDistanceChanged(_manualCm);
  }

  Future<void> _processFrame(CameraImage image) async {
    _frameCount++;
    if (_frameCount % _frameSkip != 0) return;
    if (_busy) return;
    _busy = true;
    try {
      final input = _convert(image);
      if (input == null) {
        _busy = false;
        return;
      }
      final faces = await _detector?.processImage(input) ?? [];
      if (faces.isEmpty) {
        _noFaceFrameCount++;
        if (_noFaceFrameCount > 8 && mounted) {
          setState(() {
            _distanceCm = null;
            _smoothedDistance = null;
          });
          widget.onDistanceChanged(null);
        }
        return;
      }

      _noFaceFrameCount = 0;

      final face = faces.reduce(
        (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
      );
      final faceWidthPx = face.boundingBox.width;
      if (faceWidthPx <= 10) {
        _busy = false;
        return;
      }

      // Use inter-eye distance if available for better accuracy
      double effectiveWidthPx = faceWidthPx;
      double effectiveRealWidthCm = _knownFaceWidthCm;

      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      if (leftEye != null && rightEye != null) {
        final dx = (leftEye.position.x - rightEye.position.x).toDouble();
        final dy = (leftEye.position.y - rightEye.position.y).toDouble();
        final eyeDistSq = dx * dx + dy * dy;
        if (eyeDistSq > 100) {
          effectiveWidthPx = _sqrt(eyeDistSq);
          effectiveRealWidthCm = 6.3; // Average inter-pupillary distance
        }
      }

      final rawDistance =
          (effectiveRealWidthCm * _focalPx) / effectiveWidthPx;

      // EMA smoothing
      if (_smoothedDistance == null) {
        _smoothedDistance = rawDistance;
      } else {
        _smoothedDistance =
            _emaAlpha * rawDistance + (1 - _emaAlpha) * _smoothedDistance!;
      }

      final distance = _smoothedDistance!.clamp(15.0, 200.0);

      if (mounted) {
        setState(() => _distanceCm = distance);
        widget.onDistanceChanged(distance);
      }
    } catch (_) {
      // ignore per-frame errors
    } finally {
      _busy = false;
    }
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  InputImage? _convert(CameraImage image) {
    try {
      final camera = _camera;
      if (camera == null) return null;
      final rotation = InputImageRotationValue.fromRawValue(
            camera.description.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  DistanceStatus get _status {
    final d = _useManual ? _manualCm : _distanceCm;
    if (d == null) {
      return _useManual ? DistanceStatus.unknown : DistanceStatus.noFace;
    }
    if (d < widget.minCm) return DistanceStatus.tooClose;
    if (d > widget.maxCm) return DistanceStatus.tooFar;
    return DistanceStatus.ok;
  }

  Color _statusColor() {
    switch (_status) {
      case DistanceStatus.ok:
        return const Color(0xFF22C55E);
      case DistanceStatus.tooFar:
      case DistanceStatus.tooClose:
        return const Color(0xFFF59E0B);
      case DistanceStatus.noFace:
        return const Color(0xFFEF4444);
      case DistanceStatus.unknown:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _statusIcon() {
    switch (_status) {
      case DistanceStatus.ok:
        return Icons.check_circle_rounded;
      case DistanceStatus.tooClose:
        return Icons.arrow_back_rounded;
      case DistanceStatus.tooFar:
        return Icons.arrow_forward_rounded;
      case DistanceStatus.noFace:
        return Icons.face_retouching_off_rounded;
      case DistanceStatus.unknown:
        return Icons.straighten_rounded;
    }
  }

  String _statusText(BuildContext context) {
    final d = _useManual ? _manualCm : _distanceCm;
    switch (_status) {
      case DistanceStatus.ok:
        return context
            .tr('distance_ok', args: {'cm': d!.toStringAsFixed(0)});
      case DistanceStatus.tooClose:
        return context.tr('distance_too_close');
      case DistanceStatus.tooFar:
        return context.tr('distance_too_far');
      case DistanceStatus.noFace:
        return context.tr('distance_no_face');
      case DistanceStatus.unknown:
        return context.tr('distance_manual');
    }
  }

  String _errorText(BuildContext context) {
    switch (_error) {
      case 'permission':
        return context.tr('camera_permission_denied');
      case 'no_camera':
        return context.tr('no_camera');
      case 'error':
        return context.tr('camera_error');
      default:
        return _error ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor();

    Widget preview;
    if (_initializing) {
      preview = Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    } else if (_useManual) {
      preview = Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.straighten_rounded, size: 32, color: cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              '${(_manualCm ?? 50).toStringAsFixed(0)} cm',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
    } else if (_camera != null && _camera!.value.isInitialized) {
      preview = Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor, width: 2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_camera!),
              // Face guide overlay
              if (_status == DistanceStatus.noFace)
                Center(
                  child: Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      preview = Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          preview,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(), size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _statusText(context),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('distance_target', args: {
                    'min': widget.minCm.toInt().toString(),
                    'max': widget.maxCm.toInt().toString(),
                  }),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorText(context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.error,
                        ),
                  ),
                ],
                if (_useManual) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('30',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context)
                              .copyWith(trackHeight: 4),
                          child: Slider(
                            value: (_manualCm ?? 50).clamp(30, 100),
                            min: 30,
                            max: 100,
                            divisions: 70,
                            label:
                                '${(_manualCm ?? 50).toStringAsFixed(0)} cm',
                            onChanged: (v) {
                              setState(() => _manualCm = v);
                              widget.onDistanceChanged(v);
                            },
                          ),
                        ),
                      ),
                      Text('100',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
