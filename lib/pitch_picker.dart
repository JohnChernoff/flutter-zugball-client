import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zugclient/phase_timer.dart';
import 'package:zugclient/zug_area.dart';
import 'package:forkball/zugball_fields.dart';
import 'game.dart';
import 'game_model.dart';

enum SwingType {
  normal("Normal"),
  contact("Contact"),
  power("Power"),
  bunt("Bunt"),
  none("Take Pitch"),
  hitAndRunContact("Hit and Run"),
  hitAndRunBunt("Bunt and Run");
  final String swingName;
  const SwingType(this.swingName);
}

SwingType lastSwingType = SwingType.normal;

class CombinedPitchWidget extends StatefulWidget {
  final GameModel model;
  final bool squashedWidth, squashedHeight, superSquashedWidth;
  const CombinedPitchWidget(this.model, {this.squashedWidth = false, this.squashedHeight = false, this.superSquashedWidth = false, super.key});

  @override
  State<StatefulWidget> createState() => _CombinedPitchWidgetState();
}

class _CombinedPitchWidgetState extends State<CombinedPitchWidget> with TickerProviderStateMixin {
  SwingType _selectedSwingType = lastSwingType;
  late PhaseTimerController _pitchTimerController;
  // Animation controllers for location selection
  double _px = .5, _py = .5;
  late AnimationController _crosshairController;
  late Animation<double> _crosshairAnimation;
  late AnimationController _ballController;
  late Animation<double> _ballScaleAnimation;
  late Animation<double> _ballGlowAnimation;
  String? _lastPitchKey;
  bool batting = false;

  @override
  void initState() {
    super.initState();
    setSwing(lastSwingType);
    _pitchTimerController = PhaseTimerController(this);

    _crosshairController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _crosshairAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _crosshairController, curve: Curves.elasticOut),
    );

    _ballController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _ballScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ballController, curve: Curves.elasticOut),
    );
    _ballGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ballController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pitchTimerController.disposeTimer();
    _crosshairController.dispose();
    _ballController.dispose();
    //stopWatchTimer.dispose();
    super.dispose();
  }

  void _checkForNewPitch(Game cg) {
    if (cg.lastPitchLocation != null) {
      String currentPitchKey = '${cg.lastPitchLocation?.dx}_${cg.lastPitchLocation?.dy}_${cg.lastPitch}_${cg.lastPitchSpeed}';
      if (_lastPitchKey != currentPitchKey) {
        _lastPitchKey = currentPitchKey;
        _ballController.reset();
        _ballController.forward();
      }
    }
  }

  void _showPitchSelectionDialog(BuildContext context) async {
    Game cg = widget.model.currentGame;

    List<dynamic> pList = cg.upData[ZugBallField.pitching]?[ZugBallField.pitchList] ?? [];
    Set<String> uniquePitchTypes = {};
    List<dynamic> uniquePitchList = [];
    for (var pitch in pList) {
      String pitchType = pitch[ZugBallField.pitchType] ?? '';
      if (pitchType.isNotEmpty && !uniquePitchTypes.contains(pitchType)) {
        uniquePitchTypes.add(pitchType);
        uniquePitchList.add(pitch);
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        SwingType selectedSwing = lastSwingType; // local dialog state
        int millisRemaining = cg.phaseTimeRemaining();
        Timer? countdownTimer;
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDialogState) {
            countdownTimer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
                if (millisRemaining <= 0) {
                  countdownTimer?.cancel();
                  Navigator.of(dialogContext).pop(); // auto-close if time runs out
                } else if (dialogContext.mounted) {
                  setDialogState(() {
                    millisRemaining = (millisRemaining - 100).clamp(0, cg.phaseTimeRemaining());
                  });
                }
              });
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B263B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade900],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            batting ? 'Predict Pitch' : 'Select Pitch',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    Text('Pitch clock: ${(millisRemaining / 1000).toStringAsFixed(1)}'),
                    // Swing type selector (batting only)
                    if (batting)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.sports_baseball, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "SWING TYPE",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: SwingType.values.map((SwingType type) {
                                bool isSelected = selectedSwing == type;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(
                                    type.swingName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.orange,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  selectedColor: Colors.orange,
                                  checkmarkColor: Colors.white,
                                  side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                                  onSelected: (bool selected) {
                                    setDialogState(() {
                                      selectedSwing = type;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                    // Pitch list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shrinkWrap: true,
                        itemCount: uniquePitchList.length,
                        itemBuilder: (context, i) {
                          String pitchType = uniquePitchList[i][ZugBallField.pitchType];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFF2A3B4D),
                            child: ListTile(
                              title: Text(
                                pitchType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Skill: ${uniquePitchList[i][ZugBallField.skill]}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: const Icon(Icons.arrow_forward, color: Colors.white),
                              onTap: () {
                                Navigator.of(dialogContext).pop({
                                  'pitch': pitchType,
                                  'swing': selectedSwing,
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        cg.selectedPitch = result['pitch'];
        _selectedSwingType = result['swing'];
        lastSwingType = _selectedSwingType; // persist for next dialog
      });

      // Submit the pitch
      widget.model.areaCmd(GameMsg.nextPitch, data: {
        ZugBallField.pitchType: cg.selectedPitch,
        ZugBallField.locX: cg.selectedPitchLocation.dx,
        ZugBallField.locY: cg.selectedPitchLocation.dy,
        ZugBallField.swing: _selectedSwingType.name,
      });
    }
  }


  void setSwing(SwingType type) {
    _selectedSwingType = type;
    lastSwingType = _selectedSwingType;
  }

  Widget getTimer(Game cg) {
    return _pitchTimerController.getPhaseTimerCircle(
      size: cg.phase == ZugBallPhase.selection ? 48 : 0,
      currArea: cg,
      progressColor: Colors.blue,
      backgroundColor: Colors.black,
      strokeWidth: 8,
      textColor: Colors.blue,
    );
  }

  Widget getSideIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: batting ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: batting ? Colors.orange : Colors.blue,
        ),
      ),
      child: Text(
        "${widget.superSquashedWidth ? '' : 'Currently'} ${batting ? "Batting" : "Pitching"}",
        style: theme.textTheme.titleSmall?.copyWith(
          color: batting ? Colors.orange : Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Game cg = widget.model.currentGame;
    UniqueName homeMgr = UniqueName.fromData(cg.upData[ZugBallField.homeTeam]?[ZugBallField.manager]);
    bool userHomeTeam = (homeMgr.eq(widget.model.userName));
    batting = cg.upData[ZugBallField.inningHalf] == (userHomeTeam ? "bottom" : "top");

    _checkForNewPitch(cg);

    return Card(
      elevation: 8,
      color: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.squashedWidth) Center(child: getTimer(cg)),
            // Header with status and timer
            SizedBox(
              height: 60,
              child: widget.squashedWidth
                  ? Center(child: getSideIndicator(theme))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  getSideIndicator(theme),
                  getTimer(cg),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instruction text
            Text(
              "TAP LOCATION TO ${batting ? 'PREDICT' : 'THROW'} PITCH",
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Location widget
            Expanded(
              child: _buildPitchLocationWidget(cg, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchLocationWidget(Game cg, BuildContext context) {
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

            // Show pitch selection dialog after location is chosen
            if (cg.phase == ZugBallPhase.selection) _showPitchSelectionDialog(context);
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
              child: Stack(
                children: [
                  // Background
                  Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        colors: [
                          const Color(0xFF8B4513).withOpacity(0.8),
                          const Color(0xFF654321),
                        ],
                      ),
                    ),
                  ),
                  // Strike zone
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
                  // Last pitch ball
                  if (cg.lastPitchLocation != null)
                    AnimatedBuilder(
                      animation: _ballController,
                      builder: (context, child) {
                        return Positioned(
                          left: constraints.maxWidth * cg.getRatioX(cg.lastPitchLocation?.dx) - 16,
                          top: constraints.maxHeight * cg.getRatioY(cg.lastPitchLocation?.dy) - 16,
                          child: Transform.scale(
                            scale: _ballScaleAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.8 * _ballGlowAnimation.value),
                                    blurRadius: 10 + (10 * _ballGlowAnimation.value),
                                    spreadRadius: 2 + (4 * _ballGlowAnimation.value),
                                  ),
                                  if (_ballGlowAnimation.value > 0.5)
                                    BoxShadow(
                                      color: Colors.yellow.withOpacity(0.6 * _ballGlowAnimation.value),
                                      blurRadius: 20,
                                      spreadRadius: 6,
                                    ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_baseball,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  // Crosshair
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
