import 'package:flutter/material.dart';

enum TeamDivision {
  alEast("AL_East", "American League East"),
  alCentral("AL_Central", "American League Central"),
  alWest("AL_West", "American League West"),
  nlEast("NL_East", "National League East"),
  nlCentral("NL_Central", "National League Central"),
  nlWest("NL_West", "National League West");
  const TeamDivision(this.dbColName, this.fullname);
  final String dbColName, fullname;
}

enum Team {
  boston("Boston", "Beacons", "BOS", TeamDivision.alEast),
  newYork("New York", "Bagels", "NY", TeamDivision.alEast),
  baltimore("Baltimore", "Chopsticks", "BAL", TeamDivision.alEast),
  philadelphia("Philadelphia", "Pretzels", "PHI", TeamDivision.nlEast),
  chicago("Chicago", "Moonshiners", "CHI", TeamDivision.nlCentral),
  sanDiego("San Diego", "Submarines", "SD", TeamDivision.nlWest),
  losAngeles("Los Angeles", "Avocados", "LA", TeamDivision.nlWest),
  sanFrancisco("San Francisco", "Sourdoughs", "SF", TeamDivision.nlWest),
  portland("Portland", "Proletariats", "POR", TeamDivision.alWest),
  seattle("Seattle", "Beanbags", "SEA", TeamDivision.alWest);

  const Team(this.city, this.name, this.abbrev, this.div);
  final String city, name, abbrev;
  final TeamDivision div;
}

class TeamSelectionDialog extends StatelessWidget {
  const TeamSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Group teams by division
    final Map<TeamDivision, List<Team>> teamsByDivision = {};
    for (Team team in Team.values) {
      teamsByDivision.putIfAbsent(team.div, () => []).add(team);
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Your Team',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Teams grid
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: teamsByDivision.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Division header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            entry.key.fullname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        // Teams in this division
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                          children: entry.value.map((team) {
                            return _TeamCard(
                              team: team,
                              onTap: () => Navigator.of(context).pop(team),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static method to show the dialog and return selected team
  static Future<Team?> show(BuildContext context) {
    return showDialog<Team>(
      context: context,
      builder: (context) => const TeamSelectionDialog(),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Team logo/image
              Expanded(
                flex: 4,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'images/teams/${team.abbrev}.png',
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) { //print("Error: $error");
                        // Fallback if image doesn't exist
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              team.abbrev,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Team city
              Text(
                team.city,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Team name
              Text(
                team.name,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
