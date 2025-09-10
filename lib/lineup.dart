import 'package:flutter/material.dart';
import 'package:zugclient_template/zugball_fields.dart';
import 'game.dart';

class BattingLineupWidget extends StatelessWidget {
  final Game game;
  final bool showOnlyCurrentBatter;
  final double? maxHeight;

  const BattingLineupWidget({
    super.key,
    required this.game,
    this.showOnlyCurrentBatter = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final battingTeam = game.battingTeam();
    if (battingTeam == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No batting team data available'),
        ),
      );
    }

    final lineup = battingTeam['lineup'] as List?;
    final currentAtBat = battingTeam['atBat'] as int? ?? 0;
    final teamName = battingTeam[ZugBallField.teamName] as String? ?? 'Team';

    if (lineup == null || lineup.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No lineup available for $teamName'),
        ),
      );
    }

    if (showOnlyCurrentBatter) {
      return _buildCurrentBatterCard(lineup, currentAtBat, teamName, context);
    }

    return _buildFullLineupCard(lineup, currentAtBat, teamName, context);
  }

  Widget _buildCurrentBatterCard(List lineup, int currentAtBat, String teamName, BuildContext context) {
    if (currentAtBat >= lineup.length) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Invalid batter index'),
        ),
      );
    }

    final currentBatter = lineup[currentAtBat];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Now Batting',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildBatterTile(currentBatter, currentAtBat, true, context),
          ],
        ),
      ),
    );
  }

  Widget _buildFullLineupCard(List lineup, int currentAtBat, String teamName, BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              '$teamName Batting Order',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight ?? 400,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lineup.length,
              itemBuilder: (context, index) {
                final batter = lineup[index];
                final isCurrentBatter = index == currentAtBat;
                return _buildBatterTile(batter, index, isCurrentBatter, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatterTile(dynamic batter, int index, bool isCurrentBatter, BuildContext context) {
    final playerName = batter?[ZugBallField.lastName] as String? ?? 'Unknown Player';
    final position = batter?["position"] as String? ?? '';
    final battingAvg = batter?[ZugBallField.battingAvg] as double?;
    final ops = batter?[ZugBallField.ops] as double?;
    final bats = batter?[ZugBallField.leftHanded] ? "left" : "right";
    final stats = batter?["stats"] as Map?;

    // TODO: adjust these field names based on actual data structure
    final hits = stats?['hits'] as int? ?? 0;
    final atBats = stats?['atBats'] as int? ?? 0;
    final rbi = stats?['rbi'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentBatter
            ? Colors.black
            : null,
        border: isCurrentBatter
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentBatter
              ? Colors.green
              : Theme.of(context).primaryColor,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                playerName,
                style: TextStyle(
                  fontWeight: isCurrentBatter
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (isCurrentBatter)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AT BAT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (position.isNotEmpty)
              Text(
                position,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            if (battingAvg != null && ops != null)
              Text( //TODO: fix decimals
                'AVG: .${(battingAvg * 1000).floor()}, OPS: .${(ops * 1000).floor()}, Bats: $bats',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$hits/$atBats',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$rbi RBI',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension widget for a compact horizontal lineup display
class CompactBattingLineupWidget extends StatelessWidget {
  final Game game;

  const CompactBattingLineupWidget({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final battingTeam = game.battingTeam();
    if (battingTeam == null) return const SizedBox.shrink();

    final lineup = battingTeam[ZugBallField.lineup] as List?;
    final currentAtBat = battingTeam[ZugBallField.atBat] as int? ?? 0;

    if (lineup == null || lineup.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: lineup.length,
        itemBuilder: (context, index) {
          final batter = lineup[index];
          final isCurrentBatter = index == currentAtBat;
          final playerName = batter?[ZugBallField.lastName] as String? ?? 'Unknown';

          return Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isCurrentBatter ? Colors.green : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: isCurrentBatter ? Border.all(color: Colors.green[700]!, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrentBatter ? Colors.white : Colors.grey[400],
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCurrentBatter ? Colors.green : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playerName.split(' ').last, // Show last name only
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrentBatter ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentBatter ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}