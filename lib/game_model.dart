import 'package:forkball/teams.dart';
import 'package:zug_utils/zug_dialogs.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_model.dart';
import 'package:forkball/zugball_fields.dart';
import 'game.dart';

enum GameMsg { nextPitch, pitchResult }

class GameModel extends ZugModel {

  Game get currentGame => currentArea as Game;

  Game getGame(data) => getOrCreateArea(data) as Game;

  GameModel(super.domain, super.port, super.remoteEndpoint, super.prefs,
      {super.firebaseOptions, super.localServer,super.showServMess,super.javalinServer}) {
    showServMess = true;
    modelName = "my_client";
    addFunctions({
      GameMsg.pitchResult: handlePitch,
    });
    editOption(AudioOpt.music, true);
    checkRedirect("lichess.org");
  }

  @override
  void newArea({String? title}) {
    selectTeam().then((t) =>
      areaCmd(ClientMsg.newArea,id: userName.toString(), data: {
        ZugBallField.abbrev : t?.abbrev
      })
    );
  }

  @override
  void joinArea(String id) {
    areaCmd(ClientMsg.joinArea,data: {
      id: id,
      ZugBallField.abbrev : selectTeam()
    });
  }

  Future<Team?> selectTeam() async {
    if (zugAppNavigatorKey.currentContext != null) {
      return await TeamSelectionDialog.show(zugAppNavigatorKey.currentContext!);
    }
    return null;
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

  void handlePitch(data) { //print("Handling pitch: $data");
    currentGame.setLastPitch(data);
  }

  @override
  Area createArea(data) {
    return Game(data);
  }

}