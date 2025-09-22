import 'package:forkball/schedule.dart';
import 'package:forkball/teams.dart';
import 'package:zug_utils/zug_dialogs.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_model.dart';
import 'package:forkball/zugball_fields.dart';
import 'package:zugclient/zug_option.dart';
import 'game.dart';

enum GameMsg { nextPitch, pitchResult, guessNotification, selectTeam, subPlayer, createSeason, switchSeason, listSeasons, getStandings,
getSchedule,scheduleResponse,teamMap}
enum GameOptions { gameMode }
enum GameMode {exhibition,season}

class Season {
  int id;
  String name;
  Season(this.id,this.name);
  Season.fromJson(Map<String, dynamic> json) :
        id = json[ZugBallField.seasonId],
        name = json[ZugBallField.seasonName];
}

class GameModel extends ZugModel {

  bool showSeasons = false;
  Season? currentSeason;
  List<Season> seasons = [];
  Map<int, Team> teamMap = {};

  Game get currentGame => currentArea as Game;

  Game getGame(data) => getOrCreateArea(data) as Game;

  GameModel(super.domain, super.port, super.remoteEndpoint, super.prefs,
      {super.firebaseOptions, super.localServer,super.showServMess,super.javalinServer}) {
    showServMess = true;
    modelName = "my_client";
    registerEnum(GameMode.values);
    setOptionFromEnum(GameOptions.gameMode, GameMode.exhibition.asOption(label: "Game Mode"));
    //print ("Current mode: ${getOption(GameOptions.gameMode)}");
    addFunctions({
      GameMsg.pitchResult: handlePitch,
      GameMsg.guessNotification: handleGuessNotification,
      GameMsg.listSeasons : handleSeasonList,
      GameMsg.scheduleResponse : handleSchedule,
      GameMsg.teamMap : handleTeamMap
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
      ZugBallField.abbrev : selectTeam() //TODO: await
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
    getGame(data).setLastPitch(data);
  }

  void handleGuessNotification(data) {
    currentGame.setGuessResult(data[ZugBallField.pitch] ?? false,
        data[ZugBallField.location] ?? false);
  }

  void handleSeasonList(data) {
      currentSeason = Season.fromJson(data[ZugBallField.currentSeason]);
      seasons.clear();
      for (dynamic listData in data[ZugBallField.seasons]) {
        seasons.add(Season.fromJson(listData));
      }
  }

  void handleTeamMap(data) {
    for (Map<String,dynamic> entry in data) {
      Team? team = Team.values.where((t) => t.abbrev == entry[ZugBallField.abbrev]).firstOrNull;
      if (team != null) teamMap.putIfAbsent(entry[ZugBallField.teamId], () => team);
    }
  }
  
  void handleSchedule(data) {
    final games = ScheduleParser.parseScheduleFromJson(data);
    // Parse played games
    Set<String> playedGames = {};
    if (data['playedGames'] != null) {
      for (String gameKey in data['playedGames']) {
        playedGames.add(gameKey);
      }
    }
    ZugDialogs.showClickableDialog(ScheduleViewPage(schedule: games,
        teamMap: teamMap, userTeam: Team.sanFrancisco, playedGames: playedGames));
  }

  void toggleSeasonMode() {
    showSeasons = !showSeasons;
    notifyListeners();
  }

  void createSeason(String name) {
    send(GameMsg.createSeason,data: {ZugBallField.seasonName : name});
  }

  @override
  Area createArea(data) {
    return Game(data);
  }

}