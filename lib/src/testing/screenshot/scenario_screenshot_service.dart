import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../executor/test_execution_result.dart';

/// Service responsible for capturing high-fidelity PNG screenshots of rendered
/// widgets or the physical device screen during test execution.
class ScenarioScreenshotService {
  /// Creates a [ScenarioScreenshotService].
  ScenarioScreenshotService({
    this.boundaryKey,
    this.deviceCaptureAdapter,
    this.maxInMemoryScreenshots = 50,
    this.defaultPixelRatio = 1.0,
  });

  /// Optional [GlobalKey] anchoring the target [RepaintBoundary].
  final GlobalKey? boundaryKey;

  /// Optional platform/device capture hook used when executing on physical devices or emulators.
  final Future<Uint8List?> Function(String name)? deviceCaptureAdapter;

  /// Maximum number of screenshots stored in memory before oldest entries are pruned.
  final int maxInMemoryScreenshots;

  /// Default pixel ratio used when rasterizing widget repaint boundaries.
  final double defaultPixelRatio;

  final List<ScenarioScreenshot> _capturedScreenshots = [];

  /// All screenshots captured during the lifetime of this service.
  List<ScenarioScreenshot> get capturedScreenshots =>
      List.unmodifiable(_capturedScreenshots);

  /// Captures a screenshot from the designated boundary, context, or device adapter.
  Future<ScenarioScreenshot?> capture({
    required String name,
    BuildContext? context,
    String? stepId,
    String? stepDescription,
    double? pixelRatio,
  }) async {
    final effectivePixelRatio = pixelRatio ?? defaultPixelRatio;
    final boundary = _resolveRepaintBoundary(context);
    Uint8List? pngBytes;
    double? width;
    double? height;

    // 1. Physical device / integration test adapter priority
    if (deviceCaptureAdapter != null) {
      try {
        pngBytes = await deviceCaptureAdapter!(name);
      } catch (_) {
        pngBytes = null;
      }
    }

    // 2. RenderRepaintBoundary capture fallback
    if (pngBytes == null && boundary != null && boundary.hasSize) {
      width = boundary.size.width;
      height = boundary.size.height;
      try {
        final ui.Image image =
            await boundary.toImage(pixelRatio: effectivePixelRatio);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          pngBytes = byteData.buffer.asUint8List();
        }
      } catch (_) {
        // If boundary is not ready or disposed, fail gracefully
        pngBytes = null;
      }
    }

    if (pngBytes == null) return null;

    final screenshot = ScenarioScreenshot(
      name: name,
      bytes: pngBytes,
      timestamp: DateTime.now(),
      stepId: stepId,
      stepDescription: stepDescription,
      deviceWidth: width,
      deviceHeight: height,
      pixelRatio: effectivePixelRatio,
    );

    _addScreenshot(screenshot);
    return screenshot;
  }

  RenderRepaintBoundary? _resolveRepaintBoundary(
      BuildContext? fallbackContext) {
    if (boundaryKey?.currentContext != null) {
      final ro = boundaryKey!.currentContext!.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        return ro;
      }
    }

    if (fallbackContext != null && fallbackContext.mounted) {
      final ro = fallbackContext.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        return ro;
      }

      // Search up the render tree
      RenderObject? parent = ro?.parent;
      while (parent != null) {
        if (parent is RenderRepaintBoundary) {
          return parent;
        }
        parent = parent.parent;
      }
    }

    return null;
  }

  void _addScreenshot(ScenarioScreenshot screenshot) {
    if (_capturedScreenshots.length >= maxInMemoryScreenshots) {
      _capturedScreenshots.removeAt(0); // Evict oldest
    }
    _capturedScreenshots.add(screenshot);
  }

  /// Clears all retained screenshot buffers to free memory.
  void clear() {
    _capturedScreenshots.clear();
  }

  /// Converts raw image bytes into a data URL format suitable for HTML embedding.
  static String toBase64DataUrl(Uint8List bytes) {
    final base64String = base64Encode(bytes);
    return 'data:image/png;base64,$base64String';
  }
}
