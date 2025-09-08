import 'package:flutter/material.dart';
import 'game.dart';
import 'game_model.dart';

// Enhanced PitchLocationWidget with better styling
class PitchLocationWidget extends StatefulWidget {
  final GameModel model;
  const PitchLocationWidget(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _PitchLocationWidgetState();
}

class _PitchLocationWidgetState extends State<PitchLocationWidget>
    with TickerProviderStateMixin {
  double _px = .5, _py = .5;
  late AnimationController _crosshairController;
  late Animation<double> _crosshairAnimation;

  @override
  void initState() {
    super.initState();
    _crosshairController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _crosshairAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _crosshairController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _crosshairController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Game cg = widget.model.currentGame;
    return LayoutBuilder(
      builder: (context, constraints) {
        double zoneWidth = cg.zoneWidth.toDouble();
        double zoneHeight = cg.zoneHeight.toDouble();
        double ballBuff = cg.ballBuff;

        double totalGameWidth = zoneWidth + (zoneWidth * ballBuff * 2);
        double totalGameHeight = zoneHeight + (zoneHeight * ballBuff * 2);

        double strikeZoneWidth = (zoneWidth / totalGameWidth) * constraints.maxWidth;
        double strikeZoneHeight = (zoneHeight / totalGameHeight) * constraints.maxHeight;
        double bufferX = (zoneWidth * ballBuff / totalGameWidth) * constraints.maxWidth;
        double bufferY = (zoneHeight * ballBuff / totalGameHeight) * constraints.maxHeight;

        return GestureDetector(
          onTapDown: (TapDownDetails details) {
            final localPosition = details.localPosition;
            setState(() {
              _px = (localPosition.dx / constraints.maxWidth);
              _py = (localPosition.dy / constraints.maxHeight);
            });
            cg.setSelectedPitchLocation(_px, _py);
            _crosshairController.reset();
            _crosshairController.forward();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                // Enhanced background with gradient
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      colors: [
                        const Color(0xFF8B4513).withOpacity(0.8), // Brown dirt
                        const Color(0xFF654321),
                      ],
                    ),
                  ),
                ),
                // Strike zone with better styling
                Positioned(
                  left: bufferX,
                  top: bufferY,
                  child: Container(
                    width: strikeZoneWidth,
                    height: strikeZoneHeight,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.3),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Last Pitch with glow effect
                if (cg.lastPitchLocation != null)
                  Positioned(
                    left: constraints.maxWidth * cg.getRatioX(cg.lastPitchLocation?.dx) - 16,
                    top: constraints.maxHeight * cg.getRatioY(cg.lastPitchLocation?.dy) - 16,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sports_baseball,
                          color: Colors.white, size: 32),
                    ),
                  ),
                // Animated Crosshair
                AnimatedBuilder(
                  animation: _crosshairAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: constraints.maxWidth * _px - 16,
                      top: constraints.maxHeight * _py - 16,
                      child: Transform.scale(
                        scale: _crosshairAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 32),
                        ),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
