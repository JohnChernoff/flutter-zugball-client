import 'package:zugclient/phase_timer.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient_template/zugball_fields.dart';
import 'game.dart';
import 'game_model.dart';
import 'package:flutter/material.dart';

// Enhanced PitchSelectionWidget
class PitchSelectionWidget extends StatefulWidget {
  final GameModel model;
  const PitchSelectionWidget(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _PitchSelectionWidgetState();
}

class _PitchSelectionWidgetState extends State<PitchSelectionWidget> with TickerProviderStateMixin {
  String? _selectedPitch;
  late PhaseTimerController _ptc;

  @override
  void initState() {
    super.initState();
    _ptc = PhaseTimerController(this);
  }

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
              _ptc.getPhaseTimerCircle(currArea: cg, backgroundColor: const Color(0xFF8B4513), strokeWidth: 16, textColor: Colors.white)
            ],
          ),
        ),
      ),
    );
  }
}