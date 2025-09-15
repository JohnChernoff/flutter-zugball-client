import 'package:flutter/material.dart';
import 'game.dart';

class GuessResultOverlay extends StatefulWidget {
  final Widget child;
  final Game game;

  const GuessResultOverlay({
    required this.child,
    required this.game,
    super.key,
  });

  @override
  State<GuessResultOverlay> createState() => _GuessResultOverlayState();
}

class _GuessResultOverlayState extends State<GuessResultOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Track the last timestamp we showed an animation for
  DateTime? _lastAnimatedTimestamp;
  bool _showingResult = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.bounceOut),
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showingResult = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GuessResultOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForNewGuessResult();
  }

  void _checkForNewGuessResult() {
    // Check if there's a fresh result using the simple timestamp approach
    if (widget.game.hasFreshGuessResult && !_showingResult) {

      // Check if this is a new timestamp we haven't animated yet
      if (_lastAnimatedTimestamp == null ||
          widget.game.lastGuessResultTime != _lastAnimatedTimestamp) {

        _lastAnimatedTimestamp = widget.game.lastGuessResultTime;
        _triggerResultAnimation();
      }
    }
  }

  void _triggerResultAnimation() {
    setState(() {
      _showingResult = true;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showingResult)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildResultWidget(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildResultWidget() {
    bool pitchCorrect = widget.game.guess.guessedPitch;
    bool locationCorrect = widget.game.guess.guessedLocation;
    bool bothCorrect = pitchCorrect && locationCorrect;
    bool anyCorrect = pitchCorrect || locationCorrect;

    String title;
    String subtitle;
    Color color;
    IconData icon;

    if (bothCorrect) {
      title = "PERFECT GUESS!";
      subtitle = "Both pitch and location!";
      color = Colors.green.shade700;
      icon = Icons.stars;
    } else if (anyCorrect) {
      title = "PARTIAL CORRECT!";
      subtitle = pitchCorrect ? "Got the pitch type!" : "Got the location!";
      color = Colors.orange.shade700;
      icon = Icons.check_circle;
    } else {
      title = "INCORRECT GUESS";
      subtitle = "Better luck next time!";
      color = Colors.red.shade700;
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
