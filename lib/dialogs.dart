import 'dart:async';
import 'package:flutter/material.dart';

/// Anchored dialog with fade+scale animation and auto-flip
Future<T?> showAnchoredDialog<T>({
  required BuildContext context,
  required GlobalKey anchorKey,
  required Widget Function(BuildContext, void Function([T? result])) builder,
  Offset offset = const Offset(0, 0),
  Duration duration = const Duration(milliseconds: 200),
  bool animateIn = true,
  bool animateOut = true,
  AnchorAlignment alignment = AnchorAlignment.right,
}) async {
  // Capture everything before async gap
  final overlay = Overlay.of(context);
  final renderBox = anchorKey.currentContext!.findRenderObject() as RenderBox;
  final targetPosition = renderBox.localToGlobal(Offset.zero);
  final targetSize = renderBox.size;
  final screenSize = MediaQuery.of(context).size;

  final completer = Completer<T?>();
  late OverlayEntry entry;
  final controller = _AnchoredDialogController();

  void close([T? result]) async {
    if (animateOut) await controller.reverse();
    if (!completer.isCompleted) completer.complete(result);
    entry.remove();
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  // Initial position based on alignment
  double left = targetPosition.dx;
  double top = targetPosition.dy;

  switch (alignment) {
    case AnchorAlignment.right:
      left = targetPosition.dx + targetSize.width + offset.dx;
      top = targetPosition.dy + offset.dy;
      break;
    case AnchorAlignment.left:
      left = targetPosition.dx - offset.dx;
      top = targetPosition.dy + offset.dy;
      break;
    case AnchorAlignment.below:
      left = targetPosition.dx + offset.dx;
      top = targetPosition.dy + targetSize.height + offset.dy;
      break;
    case AnchorAlignment.above:
      left = targetPosition.dx + offset.dx;
      top = targetPosition.dy - offset.dy;
      break;
  }

  entry = OverlayEntry(
    builder: (context) {
      return _AnchoredDialogContainer(
        controller: controller,
        duration: duration,
        animateIn: animateIn,
        child: Builder(
          builder: (dialogContext) {
            // Measure and flip if overflow
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final dialogRenderBox =
              dialogContext.findRenderObject() as RenderBox?;
              if (dialogRenderBox == null) return;
              final dialogSize = dialogRenderBox.size;

              double newLeft = left;
              double newTop = top;

              if (alignment == AnchorAlignment.right &&
                  left + dialogSize.width > screenSize.width) {
                newLeft = targetPosition.dx - dialogSize.width - offset.dx;
              }
              if (alignment == AnchorAlignment.left && left < 0) {
                newLeft = targetPosition.dx + targetSize.width + offset.dx;
              }
              if (alignment == AnchorAlignment.below &&
                  top + dialogSize.height > screenSize.height) {
                newTop = targetPosition.dy - dialogSize.height - offset.dy;
              }
              if (alignment == AnchorAlignment.above && top < 0) {
                newTop = targetPosition.dy + targetSize.height + offset.dy;
              }

              if (newLeft != left || newTop != top) {
                left = newLeft;
                top = newTop;
                entry.markNeedsBuild();
              }
            });

            return Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: builder(dialogContext, close),
              ),
            );
          },
        ),
      );
    },
  );

  overlay.insert(entry);

  // Transparent route for outside-tap dismiss
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) {
        return GestureDetector(
          onTap: () => close(null),
          child: Container(color: Colors.transparent),
        );
      },
    ),
  );

  return completer.future;
}

/// Placement options
enum AnchorAlignment { right, left, above, below }

/// Controller to trigger reverse animation
class _AnchoredDialogController {
  late AnimationController _controller;
  bool mounted = false;

  void attach(AnimationController controller) {
    _controller = controller;
    mounted = true;
  }

  Future<void> reverse() async {
    if (mounted) await _controller.reverse();
  }
}

/// Container with fade + scale animation
class _AnchoredDialogContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool animateIn;
  final _AnchoredDialogController controller;

  const _AnchoredDialogContainer({
    required this.child,
    required this.duration,
    required this.controller,
    this.animateIn = true,
  });

  @override
  State<_AnchoredDialogContainer> createState() =>
      _AnchoredDialogContainerState();
}

class _AnchoredDialogContainerState extends State<_AnchoredDialogContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    widget.controller.attach(_controller);

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );

    if (widget.animateIn) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

