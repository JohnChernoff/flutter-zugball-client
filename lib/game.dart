import 'dart:ui';
import 'package:zugclient/zug_area.dart';

enum ZugBallPhase {pregame}

class Game extends Area {
  final int zoneWidth = 17, zoneHeight = 42;
  final double ballBuff = .2;
  String? selectedPitch;
  Offset selectedPitchLocation = const Offset(8.5, 21);

  Game(super.data);
  //void update(dynamic data,GameModel? model) {}

  void setSelectedPitchLocation(double px, double py) {
    double totalWidth = zoneWidth + (zoneWidth * ballBuff * 2);
    double totalHeight = zoneHeight + (zoneHeight * ballBuff * 2);

    double x = (totalWidth * px) - (zoneWidth * ballBuff);
    double y = (totalHeight * (1.0 - py)) - (zoneHeight * ballBuff);

    selectedPitchLocation = Offset(x, y);
  }

  @override
  List<Enum> getPhases() {
    return ZugBallPhase.values;
  }

}