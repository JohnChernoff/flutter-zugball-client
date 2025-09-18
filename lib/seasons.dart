import 'package:flutter/material.dart';
import 'package:forkball/zugball_fields.dart';
import 'game_model.dart';

class SeasonWidget extends StatefulWidget {
  final GameModel model;
  const SeasonWidget(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => SeasonWidgetState();
}

class SeasonWidgetState extends State<SeasonWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seasons',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            // Current season display
            if (widget.model.currentSeason != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Current: ${widget.model.currentSeason!.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Season list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Seasons:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateSeasonDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...widget.model.seasons.map((season) =>
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: season.id == widget.model.currentSeason?.id
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      child: Text(
                        season.id.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(season.name),
                    trailing: season.id == widget.model.currentSeason?.id
                        ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () => _selectSeason(season),
                    selected: season.id == widget.model.currentSeason?.id,
                  ),
                ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  void _selectSeason(Season season) {
    if (season.id != widget.model.currentSeason?.id) {
      // Send switch season message to server
      widget.model.send(GameMsg.switchSeason, data: {
        ZugBallField.seasonId: season.id
      });
    }
  }

  void _showCreateSeasonDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Season'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Season Name',
            hintText: 'Enter season name...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.model.createSeason(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _notifySeasonChange(Season season) {
    // This method is no longer needed since we handle it in _selectSeason
    print('Season changed to: ${season.name} (ID: ${season.id})');
  }
}