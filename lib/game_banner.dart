import 'package:flutter/material.dart';
import 'ballpark.dart';

class BallparkBanner extends StatefulWidget {
  final Ballpark ballpark;

  const BallparkBanner({
    super.key,
    required this.ballpark,
  });

  @override
  State<StatefulWidget> createState() => _BallparkBannerState();

}

class _BallparkBannerState extends State<BallparkBanner> {

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Score section
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTeamScore(widget.ballpark.awayTeam, widget.ballpark.awayRuns, false),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[600],
                  ),
                  _buildTeamScore(widget.ballpark.homeTeam, widget.ballpark.homeRuns, widget.ballpark.inningHalf == "bottom"),
                ],
              ),
            ),

            // Divider
            _buildDivider(),

            // Game state section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Inning
                    Text(
                      widget.ballpark.inningHalf == "top" ? "T${widget.ballpark.inning}" : "B${widget.ballpark.inning}",
                      style: _infoTextStyle(color: Colors.white, fontSize: 14),
                    ),
                    // Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCountDot("B", widget.ballpark.balls, 3, Colors.green[400]!),
                        const SizedBox(width: 4),
                        _buildCountDot("S", widget.ballpark.strikes, 2, Colors.orange[400]!),
                        const SizedBox(width: 4),
                        _buildCountDot("O", widget.ballpark.outs, 2, Colors.blue[400]!),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            _buildDivider(),

            // Bases section
            Expanded(
              flex: 1,
              child: Center(
                child: _buildMiniDiamond(),
              ),
            ),

            // Divider
            _buildDivider(),

            // Player info section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sports_baseball, size: 12, color: Colors.amber[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "P: ${widget.ballpark.pitcherName}",
                            style: _infoTextStyle(color: Colors.white, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.sports, size: 12, color: Colors.blue[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "B: ${widget.ballpark.batterName} ${_formatAverage(widget.ballpark.batterAvg)}",
                            style: _infoTextStyle(color: Colors.white, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            //_buildDivider(), TextButton(onPressed: () => GamePage.showLineup, child: const Text("Lineup"))
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScore(String team, int runs, bool batting) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          team,
          style: TextStyle(
            color: batting ? Colors.amber[400] : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          runs.toString(),
          style: TextStyle(
            color: batting ? Colors.amber[400] : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 2,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.amber[600],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildCountDot(String label, int count, int maxCount, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: _infoTextStyle(color: Colors.grey[400]!, fontSize: 8),
        ),
        const SizedBox(height: 2),
        Row(
          children: List.generate(maxCount, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: index < count ? color : Colors.grey[700],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[600]!, width: 0.5),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMiniDiamond() {
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: MiniDiamondPainter(
          firstBaseOccupied: widget.ballpark.firstBaseOccupied,
          secondBaseOccupied: widget.ballpark.secondBaseOccupied,
          thirdBaseOccupied: widget.ballpark.thirdBaseOccupied,
        ),
      ),
    );
  }

  TextStyle _infoTextStyle({Color color = Colors.black, double fontSize = 12, FontWeight fontWeight = FontWeight.bold}) {
    return TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight);
  }

  String _formatAverage(double value) {
    String str = value.toStringAsFixed(3);
    return str.startsWith('0.') ? str.substring(1) : str;
  }
}

class MiniDiamondPainter extends CustomPainter {
  final bool firstBaseOccupied;
  final bool secondBaseOccupied;
  final bool thirdBaseOccupied;

  MiniDiamondPainter({
    required this.firstBaseOccupied,
    required this.secondBaseOccupied,
    required this.thirdBaseOccupied,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;

    final center = Offset(size.width / 2, size.height / 2);
    final baseOffset = size.width * 0.3;

    // Draw diamond
    final diamondPath = Path()
      ..moveTo(center.dx, center.dy + baseOffset) // home
      ..lineTo(center.dx + baseOffset, center.dy) // first
      ..lineTo(center.dx, center.dy - baseOffset) // second
      ..lineTo(center.dx - baseOffset, center.dy) // third
      ..close();
    canvas.drawPath(diamondPath, paint);

    // Draw bases
    final basePaint = Paint()..style = PaintingStyle.fill;

    final basePositions = [
      Offset(center.dx + baseOffset, center.dy), // first
      Offset(center.dx, center.dy - baseOffset), // second
      Offset(center.dx - baseOffset, center.dy), // third
    ];

    final baseOccupied = [firstBaseOccupied, secondBaseOccupied, thirdBaseOccupied];

    for (int i = 0; i < 3; i++) {
      basePaint.color = baseOccupied[i] ? Colors.red[400]! : Colors.white;
      canvas.drawCircle(basePositions[i], baseOccupied[i] ? 6 : 3, basePaint);
    }

    // Home plate
    basePaint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx, center.dy + baseOffset), 3, basePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
