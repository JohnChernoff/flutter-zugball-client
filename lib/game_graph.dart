import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:forkball/play_result.dart';
import 'game_model.dart';

class GameEventVisualizer extends StatefulWidget {
  final List<GameEvent> events;
  const GameEventVisualizer({super.key, required this.events});

  @override
  State<GameEventVisualizer> createState() => _GameEventVisualizerState();
}

class _GameEventVisualizerState extends State<GameEventVisualizer> {
  int? selectedIndex;
  String viewMode = 'score'; // 'score', 'momentum', 'counts'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewSelector(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildMainChart(),
              ),
              Container(
                width: 300,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: _buildEventDetails(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_baseball, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Game Event Visualization',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'score', label: Text('Score'), icon: Icon(Icons.scoreboard)),
              ButtonSegment(value: 'momentum', label: Text('Momentum'), icon: Icon(Icons.trending_up)),
              ButtonSegment(value: 'counts', label: Text('Counts'), icon: Icon(Icons.numbers)),
            ],
            selected: {viewMode},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => viewMode = newSelection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: viewMode == 'score'
                ? _buildScoreChart()
                : viewMode == 'momentum'
                ? _buildMomentumChart()
                : _buildCountsChart(),
          ),
          const SizedBox(height: 16),
          _buildInningMarkers(),
        ],
      ),
    );
  }

  Widget _buildScoreChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            axisNameWidget: Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
              setState(() => selectedIndex = response.lineBarSpots!.first.x.toInt());
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final event = widget.events[spot.x.toInt()];
                return LineTooltipItem(
                  '${spot.barIndex == 0 ? 'Away' : 'Home'}: ${spot.y.toInt()}\n'
                      'Inning ${event.inning} ${event.inningHalf}\n'
                      '${event.result.name}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.events.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.awayScore.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: widget.events.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.homeScore.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentumChart() {
    List<FlSpot> momentumSpots = [];
    double cumulative = 0;

    for (int i = 0; i < widget.events.length; i++) {
      final event = widget.events[i];
      final positivity = event.result.positivity.toDouble();
      final multiplier = event.inningHalf == 'bottom' ? 1.0 : -1.0;
      cumulative += positivity * multiplier;
      momentumSpots.add(FlSpot(i.toDouble(), cumulative));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            axisNameWidget: Text('Momentum', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
              setState(() => selectedIndex = response.lineBarSpots!.first.x.toInt());
            }
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: momentumSpots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.red],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.3), Colors.red.withOpacity(0.3)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: Colors.black,
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountsChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 3,
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (response?.spot != null) {
              setState(() => selectedIndex = response!.spot!.touchedBarGroupIndex);
            }
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            axisNameWidget: Text('Count', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 10 == 0) {
                  return Text('${value.toInt()}');
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: widget.events.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.balls.toDouble(),
                color: Colors.green,
                width: 2,
              ),
              BarChartRodData(
                toY: e.value.strikes.toDouble(),
                color: Colors.orange,
                width: 2,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInningMarkers() {
    Map<int, int> inningStarts = {};
    for (int i = 0; i < widget.events.length; i++) {
      final event = widget.events[i];
      if (!inningStarts.containsKey(event.inning)) {
        inningStarts[event.inning] = i;
      }
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: inningStarts.length,
        itemBuilder: (context, index) {
          final inning = inningStarts.keys.elementAt(index);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Inning $inning',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventDetails() {
    if (selectedIndex == null || selectedIndex! >= widget.events.length) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tap on the chart to view event details',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final event = widget.events[selectedIndex!];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Play #${selectedIndex! + 1}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _buildDetailRow('Result', event.result.name.toUpperCase(),
              _getResultColor(event.result)),
          _buildDetailRow('Inning', '${event.inning} ${event.inningHalf}'),
          const SizedBox(height: 16),
          const Text('Players', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildDetailRow('Hitter', event.hitter),
          _buildDetailRow('Pitcher', event.pitcher),
          const SizedBox(height: 16),
          const Text('Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildDetailRow('Balls', '${event.balls}', Colors.green),
          _buildDetailRow('Strikes', '${event.strikes}', Colors.orange),
          _buildDetailRow('Outs', '${event.outs}'),
          const SizedBox(height: 16),
          const Text('Bases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildBaseDiagram(event),
          const SizedBox(height: 16),
          const Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildDetailRow('Away', '${event.awayScore}', Colors.blue),
          _buildDetailRow('Home', '${event.homeScore}', Colors.red),
          if (event.runs > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                '${event.runs} run${event.runs > 1 ? 's' : ''} scored!',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseDiagram(GameEvent event) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(120, 120),
              painter: BaseballDiamondPainter(
                firstOccupied: event.onFirst.isNotEmpty,
                secondOccupied: event.onSecond.isNotEmpty,
                thirdOccupied: event.onThird.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResultColor(PlayResult result) {
    if (result.hit) return Colors.green;
    if (result.positivity > 0) return Colors.lightGreen;
    if (result.positivity < 0) return Colors.red;
    return Colors.grey;
  }
}

class BaseballDiamondPainter extends CustomPainter {
  final bool firstOccupied;
  final bool secondOccupied;
  final bool thirdOccupied;

  BaseballDiamondPainter({
    required this.firstOccupied,
    required this.secondOccupied,
    required this.thirdOccupied,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.brown;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const baseSize = 12.0;
    final diamondSize = size.width * 0.4;

// Draw diamond
    final path = Path()
      ..moveTo(center.dx, center.dy - diamondSize)
      ..lineTo(center.dx + diamondSize, center.dy)
      ..lineTo(center.dx, center.dy + diamondSize)
      ..lineTo(center.dx - diamondSize, center.dy)
      ..close();
    canvas.drawPath(path, paint);

// Draw bases
    _drawBase(canvas, Offset(center.dx, center.dy - diamondSize), secondOccupied, baseSize, fillPaint);
    _drawBase(canvas, Offset(center.dx + diamondSize, center.dy), firstOccupied, baseSize, fillPaint);
    _drawBase(canvas, Offset(center.dx - diamondSize, center.dy), thirdOccupied, baseSize, fillPaint);

// Home plate
    fillPaint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx, center.dy + diamondSize), baseSize / 2, fillPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + diamondSize), baseSize / 2, paint);
  }

  void _drawBase(Canvas canvas, Offset position, bool occupied, double size, Paint fillPaint) {
    fillPaint.color = occupied ? Colors.yellow : Colors.white;
    final rect = Rect.fromCenter(center: position, width: size, height: size);
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.brown);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/*
## Usage

```dart
// In your Flutter app
GameEventVisualizer(
events: yourGameEventsList,
)
```

## Features

- **Score Chart**: Track home and away scores throughout the game
- **Momentum Chart**: Visualize game momentum based on play positivity
- **Counts Chart**: See balls and strikes for each at-bat
- **Interactive**: Click any point to see detailed play information
- **Baseball Diamond**: Visual representation of runners on base
- **Inning Markers**: Quick navigation through game innings
 */
