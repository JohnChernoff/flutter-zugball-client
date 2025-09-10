import 'dart:ui';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient_template/zugball_fields.dart';

enum ZugBallPhase {pregame,selection,result,postgame,delay}

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

  Game(super.data);
  //void update(dynamic data,GameModel? model) {}

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
    double y = (totalHeight * (1.0 - py)) - (ballBuffHeight);
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
    lastPitchLocation = Offset(data[ZugBallField.locX],zoneHeight - data[ZugBallField.locY]);
    lastPitch = data[ZugBallField.pitchType];
    lastPitchSpeed = (data[ZugBallField.speed] as double).toStringAsFixed(2);
  }

  @override
  List<Enum> getPhases() {
    return ZugBallPhase.values;
  }

}