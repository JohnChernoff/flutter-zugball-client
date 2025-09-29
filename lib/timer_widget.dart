import 'dart:async';
import 'package:flutter/widgets.dart';

/// A timer that automatically calls `setState` on the widget
/// and supports periodic, one-shot, or countdown timers.
class StateTimer {
  final TickerProviderStateMixin state;
  final Duration interval;
  final int? maxTicks; // null for infinite
  final bool periodic;
  final void Function(int tick)? onTick; // tick count
  final void Function()? onFinish;

  Timer? _timer;
  int _tick = 0;

  StateTimer({
    required this.state,
    required this.interval,
    this.periodic = true,
    this.maxTicks,
    this.onTick,
    this.onFinish,
  });

  void start() {
    stop(); // cancel existing timer if any
    _tick = 0;

    if (periodic) {
      _timer = Timer.periodic(interval, (timer) => _fireTick());
    } else {
      _timer = Timer(interval, _fireTick);
    }
  }

  void _fireTick() {
    if (!state.mounted) {
      stop();
      return;
    }

    _tick++;

    // Call setState safely
    state.setState(() {
      onTick?.call(_tick);
    });

    if (!periodic && (maxTicks == null || _tick >= maxTicks!)) {
      stop();
      onFinish?.call();
    } else if (maxTicks != null && _tick >= maxTicks!) {
      stop();
      onFinish?.call();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isActive => _timer?.isActive ?? false;
}
