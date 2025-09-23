import 'package:flutter/material.dart';
import 'package:forkball/game_model.dart';
import 'package:forkball/teams.dart';

// Data models matching your JSON structure
class ScheduledGame {
  final int homeTeamId;
  final int awayTeamId;
  final int seasonId;
  final int seasonSlot;
  final int homeSlot;
  final int awaySlot;
  final bool isPlayed;

  ScheduledGame({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.seasonId,
    required this.seasonSlot,
    required this.homeSlot,
    required this.awaySlot,
    this.isPlayed = false,
  });

  factory ScheduledGame.fromJson(Map<String, dynamic> json) {
    return ScheduledGame(
      homeTeamId: json['homeTeamId'],
      awayTeamId: json['awayTeamId'],
      seasonId: json['seasonId'],
      seasonSlot: json['seasonSlot'],
      homeSlot: json['homeTeamGameNumber'],
      awaySlot: json['awayTeamGameNumber'],
    );
  }
}

class SeasonScheduleWidget extends StatefulWidget {
  final GameModel model;
  final List<ScheduledGame> schedule;
  final Map<int, Team> teamMap; // Map from database team ID to Team enum
  final Team? selectedTeam;
  final Set<String> playedGames; // Set of "homeId vs awayId" strings

  const SeasonScheduleWidget({
    super.key,
    required this.model,
    required this.schedule,
    required this.teamMap,
    this.selectedTeam,
    required this.playedGames,
  });

  @override
  State<SeasonScheduleWidget> createState() => _SeasonScheduleWidgetState();
}

class _SeasonScheduleWidgetState extends State<SeasonScheduleWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Team? _selectedTeamFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedTeamFilter = widget.selectedTeam;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Team? _getTeamById(int id) {
    return widget.teamMap[id];
  }

  List<ScheduledGame> _getFilteredGames() {
    List<ScheduledGame> games = widget.schedule;

    if (_selectedTeamFilter != null) {
      int? selectedTeamId = widget.teamMap.entries
          .where((entry) => entry.value == _selectedTeamFilter)
          .map((entry) => entry.key)
          .firstOrNull;

      if (selectedTeamId != null) {
        games = games.where((game) =>
        game.homeTeamId == selectedTeamId ||
            game.awayTeamId == selectedTeamId
        ).toList();

        // Sort by global season slot (the shared number), then assign display numbers in order
        games.sort((a, b) => a.seasonSlot.compareTo(b.seasonSlot));
      }
    } else {
      games.sort((a, b) => a.seasonSlot.compareTo(b.seasonSlot));
    }

    return games;
  }

  List<ScheduledGame> _getUpcomingGames() {
    return _getFilteredGames().where((game) =>
    !widget.playedGames.contains('${game.homeTeamId}vs${game.awayTeamId}')
    ).take(20).toList();
  }

  List<ScheduledGame> _getRecentGames() {
    return _getFilteredGames().where((game) =>
        widget.playedGames.contains('${game.homeTeamId}vs${game.awayTeamId}')
    ).toList().reversed.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Team filter dropdown
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Filter by team: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<Team?>(
                  value: _selectedTeamFilter,
                  hint: const Text('All teams'),
                  isExpanded: true,
                  onChanged: (Team? team) {
                    setState(() {
                      _selectedTeamFilter = team;
                    });
                  },
                  items: [
                    const DropdownMenuItem<Team?>(
                      value: null,
                      child: Text('All teams'),
                    ),
                    ...widget.teamMap.values.map((team) => DropdownMenuItem<Team?>(
                      value: team,
                      child: Text('${team.city} ${team.name}'),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Recent'),
            Tab(text: 'Full Schedule'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingTab(),
              _buildRecentTab(),
              _buildFullScheduleTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTab() {
    final upcomingGames = _getUpcomingGames();

    if (upcomingGames.isEmpty) {
      return const Center(child: Text('No upcoming games'));
    }

    return ListView.builder(
      itemCount: upcomingGames.length,
      itemBuilder: (context, index) {
        return _buildGameTile(upcomingGames[index], false);
      },
    );
  }

  Widget _buildRecentTab() {
    final recentGames = _getRecentGames();

    if (recentGames.isEmpty) {
      return const Center(child: Text('No games played yet'));
    }

    return ListView.builder(
      itemCount: recentGames.length,
      itemBuilder: (context, index) {
        return _buildGameTile(recentGames[index], true);
      },
    );
  }

  Widget _buildFullScheduleTab() {
    final allGames = _getFilteredGames();

    return ListView.builder(
      itemCount: allGames.length,
      itemBuilder: (context, index) {
        final game = allGames[index];
        final isPlayed = widget.playedGames.contains('${game.homeTeamId}vs${game.awayTeamId}');
        return _buildGameTile(game, isPlayed);
      },
    );
  }

  Widget _buildGameTile(ScheduledGame game, bool isPlayed) {
    final homeTeam = _getTeamById(game.homeTeamId);
    final awayTeam = _getTeamById(game.awayTeamId);

    if (homeTeam == null || awayTeam == null) {
      return const ListTile(title: Text('Unknown teams'));
    }

    final bool isUserTeamGame = _selectedTeamFilter != null &&
        (homeTeam == _selectedTeamFilter || awayTeam == _selectedTeamFilter);

    // Calculate display game number based on position in filtered games
    List<ScheduledGame> allFilteredGames = _getFilteredGames();
    int displayGameNumber = allFilteredGames.indexOf(game) + 1;

    return Card(
      // ... rest of the Card widget stays the same, but use displayGameNumber
      child: ListTile(
        leading: InkWell(
            onTap: () => widget.model.newSeasonalGame(slot: game.seasonSlot),
            child: CircleAvatar(
          backgroundColor: isUserTeamGame ? Colors.blue : Colors.grey[300],
          child: Text(
            displayGameNumber.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUserTeamGame ? Colors.white : Colors.black87,
            ),
          ),
        )),
        title: Row(
          children: [
            // Away team logo
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              child: awayTeam.getImage(),
            ),
            Text(
              awayTeam.abbrev,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: awayTeam == _selectedTeamFilter ? Colors.blue : null,
              ),
            ),
            const Spacer(),
            const Text(' @ '),
            const Spacer(),
            Text(
              homeTeam.abbrev,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: homeTeam == _selectedTeamFilter ? Colors.blue : null,
              ),
            ),
            // Home team logo
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(left: 8),
              child: homeTeam.getImage(),
            ),
          ],
        ),
        subtitle: Text(
          '${awayTeam.city} at ${homeTeam.city}',
          style: TextStyle(
            color: isPlayed ? Colors.grey[600] : null,
          ),
        ),
        trailing: isPlayed
            ? Icon(Icons.check_circle, color: Colors.green[600])
            : Icon(Icons.schedule, color: Colors.orange[600]),
      ),
    );
  }
}



// Example of how to parse the JSON from your server
class ScheduleParser {
  static List<ScheduledGame> parseScheduleFromJson(Map<String, dynamic> json) {
    final List<dynamic> gamesJson = json['games'] ?? [];
    return gamesJson.map((gameJson) => ScheduledGame.fromJson(gameJson)).toList();
  }
}
