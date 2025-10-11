import 'dart:convert';
import 'package:forkball/play_result.dart';
import 'package:http/http.dart' as http;
import 'game_event.dart';
import 'game_model.dart';

Future<GameLog?> fetchGameEventsWithContext(int gamePk) async {
  final url = Uri.parse('https://statsapi.mlb.com/api/v1.1/game/$gamePk/feed/live');
  final res = await http.get(url);
  if (res.statusCode != 200) return null;

  final data = jsonDecode(res.body);
  final plays = data['liveData']?['plays']?['allPlays'] as List?;
  if (plays == null) return null;

  List<GameEvent> events = [];
  final linescore = data['liveData']?['linescore']?['teams'] ?? {};

  // Track outs and bases across plays
  int outs = 0;
  String base1 = "", base2 = "", base3 = "";

  for (var p in plays) {
    final eventType = p['result']?['eventType'] as String?;
    final result = PlayResult.parsePlayResult(eventType);

    final count = p['count'] ?? {};
    final matchup = p['matchup'] ?? {};
    final runners = p['runners'] ?? [];
    final inning = p['about']?['inning'] ?? 0;
    final inningHalf = p['about']?['halfInning'] ?? 'top';

    // Save previous outs and base states
    final prevOuts = outs;
    final prevBase1 = base1;
    final prevBase2 = base2;
    final prevBase3 = base3;

    // Update outs
    outs = count['outs'] ?? outs;

    // Reset bases before updating
    base1 = "";
    base2 = "";
    base3 = "";

    for (var r in runners) {
      final endBase = r['movement']?['end'];
      final name = r['details']?['runner']?['fullName'] ?? "";
      if (endBase == '1B') base1 = name;
      if (endBase == '2B') base2 = name;
      if (endBase == '3B') base3 = name;
    }

    final homeScore = linescore['home']?['runs'] ?? 0;
    final awayScore = linescore['away']?['runs'] ?? 0;

    events.add(GameEvent(
      result,
      count['balls'] ?? 0,
      count['strikes'] ?? 0,
      inning,
      inningHalf,
      matchup['batter']?['fullName'] ?? "Unknown",
      matchup['pitcher']?['fullName'] ?? "Unknown",
      prevBase1,
      prevBase2,
      prevBase3,
      prevOuts,
      outs,
      p['result']?['rbi'] ?? 0,
      homeScore,
      awayScore,
      false,
      false,
    ));
  }

  return GameLog(events,"Home","Away",DateTime.now());
}
