import 'package:flutter/material.dart';

class Ballpark extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeRuns;
  final int awayRuns;
  final int inning;
  final String inningHalf;
  final int outs;
  final int balls;
  final int strikes;
  final bool firstBaseOccupied;
  final bool secondBaseOccupied;
  final bool thirdBaseOccupied;
  final String firstBaseRunner;
  final String secondBaseRunner;
  final String thirdBaseRunner;
  final String batterName;
  final String pitcherName;

  const Ballpark({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeRuns,
    required this.awayRuns,
    required this.inning,
    required this.inningHalf,
    required this.outs,
    required this.balls,
    required this.strikes,
    required this.batterName,
    required this.pitcherName,
    required this.firstBaseRunner,
    required this.secondBaseRunner,
    required this.thirdBaseRunner,
  }) : firstBaseOccupied = firstBaseRunner != "",
        secondBaseOccupied = secondBaseRunner != "",
        thirdBaseOccupied = thirdBaseRunner != "";

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 8/5, child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[100]!,
            Colors.brown[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: BallparkPainter(
          firstBaseOccupied: firstBaseOccupied,
          secondBaseOccupied: secondBaseOccupied,
          thirdBaseOccupied: thirdBaseOccupied,
          firstBaseRunner: firstBaseRunner,
          secondBaseRunner: secondBaseRunner,
          thirdBaseRunner: thirdBaseRunner,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Scoreboard
              _buildScoreboard(),

              const SizedBox(height: 20),

              // Game State Info
              Expanded(
                child: Stack(
                  children: [
                    // Count display in upper left
                    Positioned(
                      top: 20,
                      left: 20,
                      child: _buildCountDisplay(),
                    ),

                    // Player names
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: _buildPlayerInfo(),
                    ),

                    // Inning and batting team
                    Positioned(
                      top: 20,
                      right: 20,
                      child: _buildInningInfo(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildScoreboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                awayTeam,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                awayRuns.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Text(
            '-',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Column(
            children: [
              Text(
                homeTeam,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                homeRuns.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountDisplay() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black54),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BALLS: $balls',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'STRIKES: $strikes',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'OUTS: $outs',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInningInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black54),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'INNING $inning',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            inningHalf.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black54),
      ),
      child: Column(
        children: [
          Text(
            'PITCHER: $pitcherName',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'BATTER: $batterName',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BallparkPainter extends CustomPainter {
  final bool firstBaseOccupied;
  final bool secondBaseOccupied;
  final bool thirdBaseOccupied;
  final String? firstBaseRunner;
  final String? secondBaseRunner;
  final String? thirdBaseRunner;

  BallparkPainter({
    required this.firstBaseOccupied,
    required this.secondBaseOccupied,
    required this.thirdBaseOccupied,
    this.firstBaseRunner,
    this.secondBaseRunner,
    this.thirdBaseRunner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Center of the diamond (home plate area)
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.75;

    // Diamond dimensions
    final baseDistance = size.width * 0.15;

    // Base positions
    final homeX = centerX;
    final homeY = centerY;
    final firstX = centerX + baseDistance;
    final firstY = centerY - baseDistance;
    final secondX = centerX;
    final secondY = centerY - baseDistance * 2;
    final thirdX = centerX - baseDistance;
    final thirdY = centerY - baseDistance;

    // Draw infield diamond
    paint.color = Colors.brown[600]!;
    final diamondPath = Path()
      ..moveTo(homeX, homeY)
      ..lineTo(firstX, firstY)
      ..lineTo(secondX, secondY)
      ..lineTo(thirdX, thirdY)
      ..close();
    canvas.drawPath(diamondPath, paint);

    // Draw pitcher's mound
    paint.style = PaintingStyle.fill;
    paint.color = Colors.brown[400]!;
    canvas.drawCircle(
      Offset(centerX, centerY - baseDistance),
      8,
      paint,
    );

    // Draw bases
    paint.color = Colors.white;
    const baseSize = 8.0;

    // Home plate (pentagon shape)
    paint.color = Colors.white;
    final homePath = Path()
      ..moveTo(homeX - baseSize/2, homeY)
      ..lineTo(homeX - baseSize/2, homeY + baseSize)
      ..lineTo(homeX, homeY + baseSize * 1.5)
      ..lineTo(homeX + baseSize/2, homeY + baseSize)
      ..lineTo(homeX + baseSize/2, homeY)
      ..close();
    canvas.drawPath(homePath, paint);

    // First base
    _drawBase(canvas, paint, firstX, firstY, baseSize, firstBaseOccupied, firstBaseRunner);

    // Second base
    _drawBase(canvas, paint, secondX, secondY, baseSize, secondBaseOccupied, secondBaseRunner);

    // Third base
    _drawBase(canvas, paint, thirdX, thirdY, baseSize, thirdBaseOccupied, thirdBaseRunner);

    // Draw foul lines
    paint.color = Colors.white;
    paint.strokeWidth = 2.0;

    // First base foul line
    canvas.drawLine(
      Offset(homeX, homeY),
      Offset(size.width, firstY - baseDistance),
      paint,
    );

    // Third base foul line
    canvas.drawLine(
      Offset(homeX, homeY),
      Offset(0, thirdY - baseDistance),
      paint,
    );
  }

  void _drawBase(Canvas canvas, Paint paint, double x, double y, double size, bool occupied, String? runnerName) {
    // Draw base
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: size, height: size),
      paint,
    );

    // Draw border
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.black;
    paint.strokeWidth = 1.0;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: size, height: size),
      paint,
    );

    // Draw runner if occupied
    if (occupied && runnerName != null) {
      // Draw runner dot
      paint.style = PaintingStyle.fill;
      paint.color = Colors.red;
      canvas.drawCircle(Offset(x, y - 15), 6, paint);

      // Draw name background
      final textPainter = TextPainter(
        text: TextSpan(
          text: runnerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textWidth = textPainter.width;
      final textHeight = textPainter.height;

      // Background for name
      paint.color = Colors.black87;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y - 30),
            width: textWidth + 6,
            height: textHeight + 4,
          ),
          const Radius.circular(3),
        ),
        paint,
      );

      // Draw name text
      textPainter.paint(
        canvas,
        Offset(x - textWidth / 2, y - 30 - textHeight / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
