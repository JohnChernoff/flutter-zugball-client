import 'package:flutter/material.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient_template/zugball_fields.dart';
import 'ballpark.dart';
import 'game.dart';
import 'game_model.dart';

class GamePage extends StatefulWidget {
  final GameModel model;
  const GamePage(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<GamePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    widget.model.areaCmd(ClientMsg.setDeaf, data: {fieldDeafened: false});
    widget.model.areaCmd(ClientMsg.updateArea);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Game cg = widget.model.currentGame;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Dark baseball theme
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (cg.exists) ...[
                // Header with game info
                _buildGameHeader(cg, theme),
                const SizedBox(height: 16),
                // Main game content
                Expanded(child: _buildGameContent(cg, theme)),
              ] else
                _buildNoGameState(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader(Game cg, ThemeData theme) {
    return Card(
      elevation: 8,
      color: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Ballpark(
                homeTeam: cg.upData[ZugBallField.homeTeam]?[ZugBallField.teamCity] ?? "?",
                awayTeam: cg.upData[ZugBallField.awayTeam]?[ZugBallField.teamCity] ?? "?",
                homeRuns: cg.upData[ZugBallField.homeTeam]?[ZugBallField.runs] ?? 0,
                awayRuns: cg.upData[ZugBallField.awayTeam]?[ZugBallField.runs] ?? 0,
                inning: cg.upData[ZugBallField.inning] ?? 0,
                inningHalf: cg.upData[ZugBallField.inningHalf] ?? "TOP",
                outs: cg.upData[ZugBallField.outs] ?? 0,
                balls: cg.upData[ZugBallField.balls] ?? 0,
                strikes: cg.upData[ZugBallField.strikes] ?? 0,
                firstBaseRunner: cg.upData[ZugBallField.firstBase] ?? "",
                secondBaseRunner: cg.upData[ZugBallField.secondBase] ?? "",
                thirdBaseRunner: cg.upData[ZugBallField.thirdBase] ?? "",
                batterName: cg.upData[ZugBallField.atBat]?[ZugBallField.lastName] ?? "",
                pitcherName: cg.upData[ZugBallField.pitching]?[ZugBallField.lastName] ?? "",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildBatterStats(cg, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterStats(Game cg, ThemeData theme) {
    final batter = cg.upData[ZugBallField.atBat];
    final battingAvg = (batter?[ZugBallField.battingAvg] ?? 0) * 1000;
    final ops = (batter?[ZugBallField.ops] ?? 0) * 1000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "AT BAT",
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${batter?[ZugBallField.firstName] ?? ''} ${batter?[ZugBallField.lastName] ?? ''}",
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("AVG", battingAvg.toStringAsFixed(0), theme),
              _buildStatItem("OPS", ops.toStringAsFixed(0), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameContent(Game cg, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - Pitch location and info
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildPitchInfoCard(cg, theme),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  elevation: 8,
                  color: const Color(0xFF1B263B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PITCH LOCATION",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: cg.zoneWidth / cg.zoneHeight,
                            child: PitchLocationWidget(widget.model),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Middle panel - Pitch selection
        Expanded(
          flex: 2,
          child: PitchSelectionWidget(widget.model),
        ),
        const SizedBox(width: 16),
        // Right panel - Chat
        Expanded(
          flex: 3,
          child: Card(
            elevation: 8,
            color: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ZugChat(widget.model),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPitchInfoCard(Game cg, ThemeData theme) {
    return Card(
      elevation: 8,
      color: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LAST PITCH",
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cg.lastPitch ?? "None",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    "${cg.lastPitchSpeed ?? 0} MPH",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGameState(ThemeData theme) {
    return Center(
      child: Card(
        elevation: 8,
        color: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_baseball,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                "No Game Active",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Waiting for game to start...",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

// Enhanced PitchSelectionWidget
class PitchSelectionWidget extends StatefulWidget {
  final GameModel model;
  const PitchSelectionWidget(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _PitchSelectionWidgetState();
}

class _PitchSelectionWidgetState extends State<PitchSelectionWidget> {
  String? _selectedPitch;

  @override
  Widget build(BuildContext context) {
    Game cg = widget.model.currentGame;
    UniqueName homeMgr = UniqueName.fromData(cg.upData[ZugBallField.homeTeam]?[ZugBallField.manager]);
    bool userHomeTeam = (homeMgr.eq(widget.model.userName));
    bool batting = cg.upData[ZugBallField.inningHalf] == "bottom" && userHomeTeam;
    List<dynamic> pList = cg.upData[ZugBallField.pitching]?[ZugBallField.pitchList] ?? [];
    final theme = Theme.of(context);

    // Get unique pitch types to avoid duplicate radio buttons
    Set<String> uniquePitchTypes = {};
    List<dynamic> uniquePitchList = [];
    for (var pitch in pList) {
      String pitchType = pitch[ZugBallField.pitchType] ?? '';
      if (pitchType.isNotEmpty && !uniquePitchTypes.contains(pitchType)) {
        uniquePitchTypes.add(pitchType);
        uniquePitchList.add(pitch);
      }
    }

    // Reset selection if current selection is no longer available
    if (_selectedPitch != null && !uniquePitchTypes.contains(_selectedPitch)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedPitch = null;
            cg.selectedPitch = null;
          });
        }
      });
    }

    return Card(
      elevation: 8,
      color: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RadioGroup<String>(
          groupValue: _selectedPitch,
          onChanged: (String? value) {
            cg.selectedPitch = value;
            setState(() {
              _selectedPitch = value;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: batting ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: batting ? Colors.orange : Colors.blue,
                  ),
                ),
                child: Text(
                  "Currently ${batting ? "Batting" : "Pitching"}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: batting ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPitch != null
                      ? () => widget.model.areaCmd(GameMsg.nextPitch, data: {
                    ZugBallField.pitchType: cg.selectedPitch,
                    ZugBallField.locX: cg.selectedPitchLocation.dx,
                    ZugBallField.locY: cg.selectedPitchLocation.dy,
                  })
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    "SUBMIT PITCH",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "SELECT PITCH TYPE",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  key: ValueKey(uniquePitchTypes.length), // Force rebuild when pitch list changes
                  itemCount: uniquePitchList.length,
                  itemBuilder: (context, i) {
                    String pitchType = uniquePitchList[i][ZugBallField.pitchType];
                    bool isSelected = _selectedPitch == pitchType;

                    return Container(
                      key: ValueKey(pitchType), // Unique key for each item
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.white24,
                        ),
                      ),
                      child: ListTile(
                        leading: Radio<String>(
                          value: pitchType,
                          activeColor: Colors.green,
                        ),
                        title: Text(
                          pitchType,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}