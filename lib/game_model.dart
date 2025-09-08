import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_model.dart';
import 'package:zugclient_template/zugball_fields.dart';
import 'game.dart';

enum GameMsg { nextPitch, pitchResult }

class GameModel extends ZugModel {

  Game get currentGame => currentArea as Game;

  Game getGame(data) => getOrCreateArea(data) as Game;

  GameModel(super.domain, super.port, super.remoteEndpoint, super.prefs, {super.localServer,super.showServMess,super.javalinServer}) {
    showServMess = true;
    modelName = "my_client";
    addFunctions({
      GameMsg.pitchResult: handlePitch,
    });
    editOption(AudioOpt.music, true);
    checkRedirect("lichess.org");
  }

  @override
  bool handleNewPhase(data) {
    bool b = super.handleNewPhase(data);
    if (currentGame.phase == ZugBallPhase.result) {
      String resultString = data[fieldPhaseData][ZugBallField.result] ?? "";
      currentGame.lastResultLog = resultString.split("\n");
      currentGame.lastResultLog.remove("");
    }
    return b;
  }

  void handlePitch(data) {
    currentGame.setLastPitch(data);
  }

  @override
  Area createArea(data) {
    return Game(data);
  }

}