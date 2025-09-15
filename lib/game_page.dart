import 'package:flutter/material.dart';
import 'package:forkball/game_overlay.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:forkball/game_banner.dart';
import 'package:forkball/lineup.dart';
import 'package:forkball/pitch_location.dart';
import 'package:forkball/pitch_result.dart';
import 'package:forkball/pitch_selection.dart';
import 'package:forkball/zugball_fields.dart';
import 'ballpark.dart';
import 'game.dart';
import 'game_model.dart';

//TODO: classic inning by inning score banner
class GamePage extends StatefulWidget {
  final GameModel model;
  const GamePage(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<GamePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool showLineup = true;

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
    Ballpark park = Ballpark(
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
      batterName: cg.getAtBat()?[ZugBallField.lastName] ?? "",
      pitcherName: cg.upData[ZugBallField.pitching]?[ZugBallField.lastName] ?? "",
      pitcherStrikes: cg.upData[ZugBallField.pitching]?[ZugBallField.strikes] ?? 0,
      pitcherBalls: cg.upData[ZugBallField.pitching]?[ZugBallField.balls] ?? 0,
      batterAvg: cg.getAtBat()?[ZugBallField.battingAvg] ?? 0.0,
      batterOps: cg.getAtBat()?[ZugBallField.ops] ?? 0.0,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Dark baseball theme
      body: LayoutBuilder(builder:
    (BuildContext context, BoxConstraints constraints) => FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (cg.exists) ...[
                // Header with game info
                constraints.maxHeight < 1080
                    ? Row(children: [
                      Expanded(child: BallparkBanner(ballpark: park)),
                      TextButton(onPressed: () => setState(() {
                        showLineup = !showLineup;
                      }), child: Text("${showLineup ? "Hide" : "Show"} Lineup")),
                    ])
                    : Flexible(flex: 1, child: _buildGameHeader(cg, park, theme)),
                const SizedBox(height: 16),
                // Main game content
                Expanded(flex: 1, child: _buildGameContent(cg,
                    constraints.maxHeight < 1080 ? !showLineup : true, theme)),
              ] else
                _buildNoGameState(theme),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildGameHeader(Game cg, Ballpark park, ThemeData theme) {
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
              child: park,
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: BattingLineupWidget(game: cg), //_buildBatterStats(cg, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent(Game cg, bool showChat, ThemeData theme) {
    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints bc) => Row(
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
                        if (bc.maxHeight > 580) Text(
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
        // Middle panel - Pitch selection/result
        Expanded(
          flex: 2,
          child: switch(cg.phase as ZugBallPhase) {
            ZugBallPhase.pregame => const Center(child: Text("Game Not Yet Started")),
            ZugBallPhase.selection =>
                GuessResultOverlay(game: cg, child:
                PitchSelectionWidget(widget.model,
                squashedWidth: bc.maxWidth < 1080, squashedHeight: bc.maxHeight < 480)),
            ZugBallPhase.result => StylishResultsWidget(cg),
            ZugBallPhase.postgame => const Center(child: Text("Game Over")),
            ZugBallPhase.delay => const SizedBox.shrink(),
          }
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
              child: showChat ? ZugChat(widget.model) : BattingLineupWidget(game: cg, maxHeight: bc.maxHeight - 76),
            ),
          ),
        ),
      ],
    ));
  }

  Widget resultWidget(Game cg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cg.lastResultLog.length, (i) => Container(decoration:
      BoxDecoration(
          borderRadius: BorderRadiusGeometry.circular(32),
          border: Border.all(width: 1,color: Colors.white)
      ),
          child: Text("   ${cg.lastResultLog.elementAt(i)}   ",
              style: const TextStyle(color: Colors.white))),
    ));
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
            SingleChildScrollView(padding: const EdgeInsets.all(2.0), scrollDirection: Axis.horizontal, child: Row(
              //mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  cg.lastPitch ?? "None",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    "${cg.lastPitchSpeed ?? '0'} MPH",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )),
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
              const Icon(
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


