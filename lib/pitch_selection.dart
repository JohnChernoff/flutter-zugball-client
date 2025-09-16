import 'package:zugclient/phase_timer.dart';
import 'package:zugclient/zug_area.dart';
import 'package:forkball/zugball_fields.dart';
import 'game.dart';
import 'game_model.dart';
import 'package:flutter/material.dart';

enum SwingType {
  normal("Normal"),
  contact("Contact"),
  power("Power"),
  bunt("Bunt"),
  none("Take Pitch"),
  hitAndRunContact("Hit and Run"),
  hitAndRunBunt("Bunt and Run");
  final String swingName;
  const SwingType(this.swingName);
}

SwingType lastSwingType = SwingType.normal;
// Enhanced PitchSelectionWidget
class PitchSelectionWidget extends StatefulWidget {
  final GameModel model;
  final bool squashedWidth, squashedHeight;
  const PitchSelectionWidget(this.model, {this.squashedWidth = false, this.squashedHeight = false, super.key});

  @override
  State<StatefulWidget> createState() => _PitchSelectionWidgetState();
}

class _PitchSelectionWidgetState extends State<PitchSelectionWidget> with TickerProviderStateMixin {
  String? _selectedPitch;
  SwingType _selectedSwingType = lastSwingType;
  late PhaseTimerController _ptc;

  @override
  void initState() {
    super.initState();
    setSwing(lastSwingType);
    _ptc = PhaseTimerController(this);
  }

  @override
  void dispose() {
    _ptc.disposeTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Game cg = widget.model.currentGame;
    UniqueName homeMgr = UniqueName.fromData(cg.upData[ZugBallField.homeTeam]?[ZugBallField.manager]);
    bool userHomeTeam = (homeMgr.eq(widget.model.userName));
    bool batting = cg.upData[ZugBallField.inningHalf] == "bottom" && userHomeTeam;

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
              SizedBox(height: 80, child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            "${widget.squashedWidth ? '' : 'Currently'} ${batting ? "Batting" : "Pitching"}",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: batting ? Colors.orange : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ))),
                    Expanded(flex: 1, child: _ptc.getPhaseTimerCircle(
                        size: widget.squashedHeight ? 48 : null,
                        currArea: cg,
                        progressColor: Colors.blue,
                        backgroundColor: Colors.black,
                        strokeWidth: 8,
                        textColor: Colors.blue))
                  ])),
              const SizedBox(height: 16),

              // Swing Type Selector (only show when batting)
              if (batting) ...[
                _buildSwingTypeSelector(theme),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPitch != null
                      ? () => widget.model.areaCmd(GameMsg.nextPitch, data: {
                    ZugBallField.pitchType: cg.selectedPitch,
                    ZugBallField.locX: cg.selectedPitchLocation.dx,
                    ZugBallField.locY: cg.selectedPitchLocation.dy,
                    ZugBallField.swing: _selectedSwingType.name,
                  }) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: widget.squashedHeight ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    batting ? "PREDICT PITCH" : "THROW PITCH",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!widget.squashedHeight) Text(
                "SELECT PITCH TYPE",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: getPitchView(cg, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwingTypeSelector(ThemeData theme) {
    if (widget.squashedHeight) {
      // Compact dropdown for small heights
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.sports_baseball, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              "Swing:",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SwingType>(
                  value: _selectedSwingType,
                  dropdownColor: const Color(0xFF2A3B4D),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                  onChanged: (SwingType? value) {
                    if (value != null) {
                      setState(() {
                        setSwing(value);
                      });
                    }
                  },
                  items: SwingType.values.map((SwingType type) {
                    return DropdownMenuItem<SwingType>(
                      value: type,
                      child: Text(
                        type.name,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Full swing type selector for normal heights
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_baseball, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  "SWING TYPE",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: SwingType.values.map((SwingType type) {
                bool isSelected = _selectedSwingType == type;
                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    type.swingName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.orange,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  selectedColor: Colors.orange,
                  checkmarkColor: Colors.white,
                  side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                  onSelected: (bool selected) {
                    setState(() {
                      setSwing(type);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    }
  }

  void setSwing(SwingType type) {
    _selectedSwingType = type;
    lastSwingType = _selectedSwingType;
    if (_selectedSwingType == SwingType.none) {
      String? firstPitch = widget.model.currentGame.upData[ZugBallField.pitching]?[ZugBallField.pitchList]?[0]?[ZugBallField.pitchType];
      if (firstPitch != null) _selectedPitch = firstPitch;
    }
  }

  Widget getPitchView(Game cg, BuildContext context) {
    final theme = Theme.of(context);
    List<dynamic> pList = cg.upData[ZugBallField.pitching]?[ZugBallField.pitchList] ?? [];

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

    // Use dropdown for low height layouts
    if (widget.squashedHeight) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedPitch,
            hint: Text(
              "Select Pitch Type",
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            dropdownColor: const Color(0xFF2A3B4D),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            isExpanded: true,
            onChanged: (String? value) {
              cg.selectedPitch = value;
              setState(() {
                _selectedPitch = value;
              });
            },
            items: uniquePitchList.map<DropdownMenuItem<String>>((pitch) {
              String pitchType = pitch[ZugBallField.pitchType];
              return DropdownMenuItem<String>(
                value: pitchType,
                child: Text(
                  "$pitchType (${pitch[ZugBallField.skill]})",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    // Regular radio button list for normal heights
    return ClipRect(
      child: ListView.builder(
        key: ValueKey(uniquePitchTypes.length),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: uniquePitchList.length,
        itemBuilder: (context, i) {
          String pitchType = uniquePitchList[i][ZugBallField.pitchType];
          bool isSelected = _selectedPitch == pitchType;
          return Container(
            key: ValueKey(pitchType),
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
                "$pitchType (${uniquePitchList[i][ZugBallField.skill]})",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: false,
            ),
          );
        },
      ),
    );
  }
}