import 'package:flutter/material.dart';
import 'game_event.dart';
import 'play_result.dart';
import 'game_model.dart';

class SonificationWidgetWrapper extends StatelessWidget {
  final GameModel gameModel;

  const SonificationWidgetWrapper({
    required this.gameModel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to GameModel changes
    return ListenableBuilder(
      listenable: gameModel,
      builder: (context, child) {
        return SonificationWidget(
          gameLog: gameModel.gameLog?.log ?? [],
          currentIndex: gameModel.sonificationIndex,
          isPlaying: gameModel.sonificationPlaying,
          onPlayPause: () => gameModel.toggleSonificationPlayback(),
          onSeek: (int value) => gameModel.seekSonification(value),
        );
      },
    );
  }
}

class SonificationWidget extends StatelessWidget {
  final List<GameEvent> gameLog;
  final int currentIndex;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final ValueChanged<int> onSeek;

  const SonificationWidget({
    required this.gameLog,
    required this.currentIndex,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (gameLog.isEmpty) {
      return const Center(child: Text('No game events'));
    }

    final event = gameLog[currentIndex];
    final inningDisplay = '${event.inning} ${event.inningHalf == 'top' ? '▲' : '▼'}';
    final countDisplay = '${event.balls}-${event.strikes}';
    final scoreDiff = (event.homeScore - event.awayScore).abs();
    final isClutch = event.clutch(event.homeScore, event.awayScore);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ScoreCard(
                        team: 'HOME',
                        score: event.homeScore,
                        isLeading: event.homeScore > event.awayScore,
                      ),
                      Column(
                        children: [
                          Text(
                            inningDisplay,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            countDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      _ScoreCard(
                        team: 'AWAY',
                        score: event.awayScore,
                        isLeading: event.awayScore > event.homeScore,
                      ),
                    ],
                  ),
                  if (isClutch)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on, color: Colors.red[300], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CLUTCH SITUATION',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // At-Bat Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Batter', event.hitter),
                  _InfoRow('Pitcher', event.pitcher),
                  _InfoRow('Result', _resultString(event.result)),
                  if (event.runs > 0)
                    _InfoRow('Runs Scored', event.runs.toString(),
                        valueColor: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bases
            _BasesDisplay(event: event),
            const SizedBox(height: 16),

            // Tension & Momentum Meters
            Row(
              children: [
                Expanded(
                  child: _TensionMeter(tension: event.tension),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MomentumMeter(
                    scoreDiff: scoreDiff,
                    isHomeLeading: event.homeScore > event.awayScore,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: currentIndex > 0
                      ? () => onSeek(currentIndex - 1)
                      : null,
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: onPlayPause,
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: currentIndex < gameLog.length - 1
                      ? () => onSeek(currentIndex + 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slider
            Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (gameLog.length - 1).toDouble(),
              onChanged: (v) => onSeek(v.toInt()),
              label: '${currentIndex + 1}/${gameLog.length}',
            ),
          ],
        ),
      ),
    );
  }

  String _resultString(PlayResult result) {
    return result.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
          (m) => ' ${m[0]}',
    ).trim();
  }
}

class _ScoreCard extends StatelessWidget {
  final String team;
  final int score;
  final bool isLeading;

  const _ScoreCard({
    required this.team,
    required this.score,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          team,
          style: TextStyle(
            fontSize: 12,
            color: isLeading ? Colors.amber : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isLeading ? Colors.amber : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BasesDisplay extends StatelessWidget {
  final GameEvent event;

  const _BasesDisplay({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'BASES',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _DiamondPainter(),
                ),
                // First Base (right) - positioned at right side of diamond
                Positioned(
                  right: 8,
                  top: 54,
                  child: _BaseBubble(
                    name: event.onFirst,
                    label: '1B',
                  ),
                ),
                // Second Base (top center) - positioned at top of diamond
                Positioned(
                  left: 54,
                  top: 8,
                  child: _BaseBubble(
                    name: event.onSecond,
                    label: '2B',
                  ),
                ),
                // Third Base (left) - positioned at left side of diamond
                Positioned(
                  left: 8,
                  top: 54,
                  child: _BaseBubble(
                    name: event.onThird,
                    label: '3B',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Runners: ${event.runnersOnBase}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseBubble extends StatelessWidget {
  final String name;
  final String label;

  const _BaseBubble({
    required this.name,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final occupied = name.isNotEmpty;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: occupied ? Colors.amber : Colors.transparent,
        border: Border.all(
          color: occupied ? Colors.amber : Colors.white30,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          occupied ? '✓' : label,
          style: TextStyle(
            color: occupied ? Colors.black : Colors.white30,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    const offset = 30.0;

    canvas.drawLine(center, Offset(center.dx + offset, center.dy), paint);
    canvas.drawLine(center, Offset(center.dx, center.dy + offset), paint);
    canvas.drawLine(center, Offset(center.dx - offset, center.dy), paint);
    canvas.drawLine(center, Offset(center.dx, center.dy - offset), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TensionMeter extends StatelessWidget {
  final int tension;

  const _TensionMeter({required this.tension});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'TENSION',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (tension / 10).clamp(0, 1),
              minHeight: 20,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(
                tension > 6 ? Colors.red : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tension.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentumMeter extends StatelessWidget {
  final int scoreDiff;
  final bool isHomeLeading;

  const _MomentumMeter({
    required this.scoreDiff,
    required this.isHomeLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'MOMENTUM',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: !isHomeLeading ? 0.5 - (scoreDiff / 10) : 0.5,
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: isHomeLeading ? 0.5 + (scoreDiff / 10) : 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
