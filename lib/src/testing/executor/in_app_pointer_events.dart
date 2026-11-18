import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Injects synthetic pointer events for in-app tests without colliding with
/// the platform mouse pointer (id `0` on web), which otherwise corrupts hover
/// hit-test state and can dismiss overlays.
abstract final class InAppPointerEvents {
  static int _nextPointer = 1000;

  static int _allocatePointer() => _nextPointer++;

  static void _hitTestAt(Offset globalPosition) {
    final result = HitTestResult();
    // ignore: deprecated_member_use
    RendererBinding.instance.hitTest(result, globalPosition);
  }

  static void _send(PointerEvent event) {
    GestureBinding.instance.handlePointerEvent(event);
  }

  /// Full tap at [globalPosition].
  static Future<void> tapAt(Offset globalPosition) async {
    _hitTestAt(globalPosition);
    final pointer = _allocatePointer();
    const kind = PointerDeviceKind.touch;

    _send(PointerAddedEvent(pointer: pointer, position: globalPosition));
    _send(PointerDownEvent(
      pointer: pointer,
      position: globalPosition,
      kind: kind,
    ));
    _send(PointerUpEvent(
      pointer: pointer,
      position: globalPosition,
      kind: kind,
    ));
    _send(PointerRemovedEvent(pointer: pointer, position: globalPosition));
    await _endOfFrame();
  }

  /// Press and hold at [globalPosition] for [duration], then release.
  static Future<void> longPressAt(
    Offset globalPosition, {
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    _hitTestAt(globalPosition);
    final pointer = _allocatePointer();
    const kind = PointerDeviceKind.touch;

    _send(PointerAddedEvent(pointer: pointer, position: globalPosition));
    _send(PointerDownEvent(
      pointer: pointer,
      position: globalPosition,
      kind: kind,
    ));
    await Future<void>.delayed(duration);
    _send(PointerUpEvent(
      pointer: pointer,
      position: globalPosition,
      kind: kind,
    ));
    _send(PointerRemovedEvent(pointer: pointer, position: globalPosition));
    await _endOfFrame();
  }

  /// Drags from [start] to [end].
  static Future<void> dragLine(
    Offset start,
    Offset end, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    _hitTestAt(start);
    final pointer = _allocatePointer();
    const kind = PointerDeviceKind.touch;

    _send(PointerAddedEvent(pointer: pointer, position: start));
    _send(PointerDownEvent(pointer: pointer, position: start, kind: kind));

    final steps = (duration.inMilliseconds / 16).ceil().clamp(1, 60);
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final position = Offset.lerp(start, end, t)!;
      await Future<void>.delayed(duration ~/ steps);
      _send(PointerMoveEvent(
        pointer: pointer,
        position: position,
        delta: position -
            (i == 1 ? start : Offset.lerp(start, end, (i - 1) / steps)!),
        kind: kind,
      ));
    }

    _send(PointerUpEvent(pointer: pointer, position: end, kind: kind));
    _send(PointerRemovedEvent(pointer: pointer, position: end));
    await _endOfFrame();
  }

  static Future<void> _endOfFrame() async {
    final binding = WidgetsBinding.instance;
    if (binding.runtimeType.toString().contains('AutomatedTest')) {
      await Future<void>.value();
      return;
    }
    await SchedulerBinding.instance.endOfFrame;
  }
}
