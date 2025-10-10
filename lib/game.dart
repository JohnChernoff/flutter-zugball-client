import 'dart:ui';
import 'package:forkball/zugball_fields.dart';
import 'package:zugclient/zug_area.dart';

enum ZugBallPhase {pregame,selection,result,postgame,delay}
enum Side {home,away}
enum InningHalf {top,bottom}

class Count {
  int balls, strikes, pitches;
  bool _fin = false;
  Count(this.balls, this.strikes, {this.pitches = 0});

  bool ball() {
    if (!finished()) {
      pitches++;
      if (++balls > 3) {
        _fin = true;
      } return _fin;
    } return false;
  }

  bool strike() {
    if (!finished()) {
      pitches++;
      if (++strikes > 2) {
        _fin = true;
      } return _fin;
    } return false;
  }

  bool finished() => _fin;

  bool eq(Count count) => balls == count.balls && strikes == count.strikes;
}

class Bases {
  bool first,second,third;
  Bases(this.first,this.second,this.third);
  bool eq(Bases bases) => first == bases.first && second == bases.second && third == bases.third;
  @override
  String toString() {
    return "${(first ? 'x' : '-')} ${(second ? 'x' : '-')} ${(third ? 'x' : '-')} ";
  }
}

class Guess {
  bool guessedPitch, guessedLocation;
  Guess(this.guessedPitch,this.guessedLocation);
}

// Minimal changes to your existing Game class
class Game extends Area {
  final double zoneWidth = 17, zoneHeight = 42;
  final double ballBuff = .2;
  String? lastPitchSpeed;
  String? selectedPitch, lastPitch;
  Offset selectedPitchLocation = const Offset(8.5, 21);
  Offset? lastPitchLocation;
  double get ballBuffWidth => zoneWidth * ballBuff;
  double get ballBuffHeight => zoneHeight * ballBuff;
  List<String> lastResultLog = [];
  Guess guess = Guess(false, false);
  DateTime? lastGuessResultTime;

  Game(super.data);

  void setGuessResult(bool pitchCorrect, bool locationCorrect) {
    guess = Guess(pitchCorrect, locationCorrect);
    lastGuessResultTime = DateTime.now();
  }

  // Helper method to check if result is fresh
  bool get hasFreshGuessResult {
    if (lastGuessResultTime == null) return false;
    if (!guess.guessedPitch && !guess.guessedLocation) return false;
    return DateTime.now().difference(lastGuessResultTime!).inSeconds < 5;
  }

  // Clear old results
  void clearOldResults() {
    if (!hasFreshGuessResult) {
      guess = Guess(false, false);
      lastGuessResultTime = null;
    }
  }

  dynamic battingTeam() {
    return (upData[ZugBallField.inningHalf] == ZugBallField.topHalf)
        ? upData[ZugBallField.awayTeam]
        : upData[ZugBallField.homeTeam];
  }

  dynamic getAtBat() {
    int i = battingTeam()?[ZugBallField.atBat] ?? 0;
    return battingTeam()?[ZugBallField.lineup]?[i];
  }

  void setSelectedPitchLocation(double px, double py) {
    double totalWidth = zoneWidth + (ballBuffWidth * 2);
    double totalHeight = zoneHeight + (ballBuffHeight * 2);
    double x = (totalWidth * px) - (ballBuffWidth);
    double y = (totalHeight * (py)) - (ballBuffHeight);
    selectedPitchLocation = Offset(x, y);
  }

  double getRatioX(double? x) {
    if (x == null) return .5;
    return (x + ballBuffWidth) / ((zoneWidth + (ballBuffWidth * 2)));
  }

  double getRatioY(double? y) {
    if (y == null) return .5;
    return (y + ballBuffHeight) / ((zoneHeight + (ballBuffHeight * 2)));
  }

  void setLastPitch(dynamic data) {
    lastPitchLocation = Offset(data[ZugBallField.locX], zoneHeight - data[ZugBallField.locY]);
    lastPitch = data[ZugBallField.pitchType];
    lastPitchSpeed = (data[ZugBallField.speed] as double).toStringAsFixed(2);
  }

  static Side getBattingSide({String? inningHalf, InningHalf inningHalfEnum = InningHalf.top}) {
    if (inningHalf != null) return inningHalf == ZugBallField.topHalf ? Side.away : Side.home;
    return inningHalfEnum == InningHalf.top ? Side.away : Side.home;
  }

  @override
  List<Enum> getPhases() {
    return ZugBallPhase.values;
  }
}
