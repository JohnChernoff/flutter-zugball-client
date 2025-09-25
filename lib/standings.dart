import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/picker.dart';
import 'package:forkball/game_model.dart';
import 'package:forkball/teams.dart';
import 'package:forkball/zugball_fields.dart';

// Data models
class TeamStanding {
  final int teamId;
  final String city;
  final String name;
  final String abbreviation;
  final int wins;
  final int losses;
  final int gamesPlayed;
  final double winPercentage;
  final int runsFor;
  final int runsAgainst;
  final int runDifferential;

  TeamStanding({
    required this.teamId,
    required this.city,
    required this.name,
    required this.abbreviation,
    required this.wins,
    required this.losses,
    required this.gamesPlayed,
    required this.winPercentage,
    required this.runsFor,
    required this.runsAgainst,
    required this.runDifferential,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    return TeamStanding(
      teamId: json['teamId'],
      city: json['city'],
      name: json['name'],
      abbreviation: json['abbreviation'],
      wins: json['wins'],
      losses: json['losses'],
      gamesPlayed: json['gamesPlayed'],
      winPercentage: json['winPercentage'].toDouble(),
      runsFor: json['runsFor'],
      runsAgainst: json['runsAgainst'],
      runDifferential: json['runDifferential'],
    );
  }

  String get record => '$wins-$losses';
  String get winPctDisplay => winPercentage.toStringAsFixed(3);
  String get runDiffDisplay => runDifferential >= 0 ? '+$runDifferential' : '$runDifferential';

  Team? get team => Team.values.where((t) => t.abbrev == abbreviation).firstOrNull;
}

class DivisionStandings {
  final String division;
  final List<TeamStanding> teams;

  DivisionStandings({
    required this.division,
    required this.teams,
  });

  factory DivisionStandings.fromJson(Map<String, dynamic> json) {
    return DivisionStandings(
      division: json['division'],
      teams: (json['teams'] as List)
          .map((team) => TeamStanding.fromJson(team))
          .toList(),
    );
  }
}

class SeasonStandings {
  final int seasonId;
  final String seasonName;
  final List<DivisionStandings> divisions;

  SeasonStandings({
    required this.seasonId,
    required this.seasonName,
    required this.divisions,
  });

  factory SeasonStandings.fromJson(Map<String, dynamic> json) {
    return SeasonStandings(
      seasonId: json[ZugBallField.seasonId],
      seasonName: json[ZugBallField.seasonName],
      divisions: (json['divisions'] as List)
          .map((division) => DivisionStandings.fromJson(division))
          .toList(),
    );
  }
}

class StandingsWidget extends StatefulWidget {
  final GameModel model;

  const StandingsWidget({
    super.key,
    required this.model,
  });

  @override
  State<StandingsWidget> createState() => _StandingsWidgetState();
}

class _StandingsWidgetState extends State<StandingsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Create tabs for each division
    int divisionCount = widget.model.currentStandings?.divisions.length ?? 0;
    _tabController = TabController(length: divisionCount + 1, vsync: this); // +1 for "All" tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final standings = widget.model.currentStandings;

    if (standings == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No standings data available', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.model.requestStandings(),
              icon: const Icon(Icons.refresh),
              label: const Text('Load Standings'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade900,
            Colors.blue.shade800,
            Colors.indigo.shade700,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  ElevatedButton(onPressed: () {
                    Picker(
                      adapter: NumberPickerAdapter(data: [
                        const NumberPickerColumn(begin: 1, end: 162, jump: 1),
                      ]),
                      title: const Text('Select Day'),
                      onConfirm: (Picker picker, List<int> value) {
                        print('Selected: ${picker.getSelectedValues()}');
                      },
                    ).showDialog(context).then((onValue) =>
                    widget.model.send(GameMsg.simulateSeason, data: {
                      ZugBallField.seasonId : widget.model.currentSeason?.id,
                      ZugBallField.day : onValue?.first
                    }));
                    }, child: const Text("Simulate")),
                ]),
                Row(
                  children: [
                    const Icon(Icons.sports_baseball, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            standings.seasonName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Season Standings',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => widget.model.requestStandings(),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          if (standings.divisions.isNotEmpty)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                const Tab(text: 'All'),
                ...standings.divisions.map((division) =>
                    Tab(text: division.division.replaceAll(' League ', ' ').replaceAll('American', 'AL').replaceAll('National', 'NL'))),
              ],
            ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllDivisionsTab(standings),
                ...standings.divisions.map((division) => _buildDivisionTab(division)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDivisionsTab(SeasonStandings standings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: standings.divisions.length,
      itemBuilder: (context, index) {
        final division = standings.divisions[index];
        return _buildDivisionCard(division, isCompact: true);
      },
    );
  }

  Widget _buildDivisionTab(DivisionStandings division) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildDivisionCard(division, isCompact: false),
    );
  }

  Widget _buildDivisionCard(DivisionStandings division, {required bool isCompact}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade800,
            ],
          ),
        ),
        child: Column(
          children: [
            // Division Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    division.division,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const SizedBox(width: 40), // Logo space
                  Expanded(flex: 3, child: Text('Team', style: headerTxtStyle())),
                  Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: headerTxtStyle())),
                  Expanded(flex: 1, child: Text('L', textAlign: TextAlign.center, style: headerTxtStyle())),
                  Expanded(flex: 1, child: Text('PCT', textAlign: TextAlign.center, style: headerTxtStyle())),
                  if (!isCompact) ...[
                    Expanded(flex: 1, child: Text('RF', textAlign: TextAlign.center, style: headerTxtStyle())),
                    Expanded(flex: 1, child: Text('RA', textAlign: TextAlign.center, style: headerTxtStyle())),
                    Expanded(flex: 1, child: Text('DIFF', textAlign: TextAlign.center, style: headerTxtStyle())),
                  ],
                ],
              ),
            ),

            // Teams
            ...division.teams.asMap().entries.map((entry) {
              final index = entry.key;
              final team = entry.value;
              return _buildTeamRow(team, index + 1, isCompact);
            }),
          ],
        ),
      ),
    );
  }

  TextStyle headerTxtStyle() {
    return const TextStyle(fontWeight: FontWeight.bold, color: Colors.black);
  }

  Widget _buildTeamRow(TeamStanding teamStanding, int rank, bool isCompact) {
    final team = teamStanding.team;
    final isFirstPlace = rank == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isFirstPlace ? Colors.green.shade900 : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Rank and logo
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isFirstPlace ? Colors.amber : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFirstPlace ? Colors.amber.shade800 : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (team != null)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: team.getImage(),
                  ),
              ],
            ),
          ),

          // Team name
          Expanded(
            flex: 3,
            child: Text(
              '${teamStanding.city} ${teamStanding.name}',
              style: TextStyle(
                fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.w500,
                color: team?.color1 ?? Colors.black87,
              ),
            ),
          ),

          // Stats
          Expanded(
            flex: 1,
            child: Text(
              '${teamStanding.wins}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${teamStanding.losses}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              teamStanding.winPctDisplay,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal),
            ),
          ),

          // Extended stats (only in detailed view)
          if (!isCompact) ...[
            Expanded(
              flex: 1,
              child: Text(
                '${teamStanding.runsFor}',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${teamStanding.runsAgainst}',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                teamStanding.runDiffDisplay,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal,
                  color: teamStanding.runDifferential >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
