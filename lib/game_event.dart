import 'package:forkball/play_result.dart';

class GameEvent {
  final PlayResult result;
  String hitter, pitcher, onFirst, onSecond, onThird, inningHalf;
  int balls, strikes, inning, prevOuts, outs, runs, homeScore, awayScore;
  bool guessedPitch, guessedLocation;

  GameEvent(this.result,this.balls,this.strikes,this.inning, this.inningHalf,
      this.hitter,this.pitcher,this.onFirst,this.onSecond,this.onThird,
      this.prevOuts,this.outs,this.runs,this.homeScore,this.awayScore,
      this.guessedPitch,this.guessedLocation);

  /// Create a GameEvent from a JSON map.
  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    PlayResult.parsePlayResult(json['result'] ?? 'Unknown'),
    json['balls'] ?? 0,
    json['strikes'] ?? 0,
    json['inning'] ?? 0,
    json['inningHalf'] ?? 'top',
    json['hitter'] ?? 'Unknown',
    json['pitcher'] ?? 'Unknown',
    json['onFirst'],
    json['onSecond'],
    json['onThird'],
    json['prevOuts'] ?? 0,
    json['outs'] ?? 0,
    json['runs'] ?? 0,
    json['homeScore'] ?? 0,
    json['awayScore'] ?? 0,
    json['guessedPitch'] ?? false,
    json['guessedLocation'] ?? false,
  );

  /// Convert a GameEvent to a JSON map.
  Map<String, dynamic> toJson() => {
    'result': result,
    'balls': balls,
    'strikes': strikes,
    'inning': inning,
    'inningHalf': inningHalf,
    'hitter': hitter,
    'pitcher': pitcher,
    'onFirst': onFirst,
    'onSecond': onSecond,
    'onThird': onThird,
    'prevOuts': prevOuts,
    'outs': outs,
    'runs': runs,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'guessedPitch': guessedPitch,
    'guessedLocation': guessedLocation,
  };
}

extension GameEventSonification on GameEvent {
  /// Number of runners on base
  int get runnersOnBase {
    int n = 0;
    if (onFirst.isNotEmpty) n++;
    if (onSecond.isNotEmpty) n++;
    if (onThird.isNotEmpty) n++;
    return n;
  }

  /// Tension metric: outs * 2 + runners
  int get tension => prevOuts * 2 + runnersOnBase;

  /// Clutch: late inning, close score
  bool clutch(int homeScoreRef, int awayScoreRef) {
    final scoreDiff = (homeScoreRef - awayScoreRef).abs();
    return inning >= 7 && scoreDiff <= 2;
  }
}

