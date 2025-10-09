import 'package:flutter/material.dart' show Icon, Icons;
import 'package:forkball/play_result.dart';
import 'package:forkball/schedule.dart';
import 'package:forkball/standings.dart';
import 'package:forkball/teams.dart';
import 'package:zug_music/zug_midi.dart';
import 'package:zug_music/zug_music.dart';
import 'package:zug_utils/zug_dialogs.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_model.dart';
import 'package:forkball/zugball_fields.dart';
import 'package:zugclient/zug_option.dart';
import 'game.dart';

enum GameMsg { nextPitch, pitchResult, guessNotification, selectTeam, subPlayer, createSeason, switchSeason, listSeasons,
  getStandings, standingsResponse, getSchedule, scheduleResponse, teamMap, simulateSeason, gameEvent, gameLog}
enum GameOptions { team }
enum GameMode {exhibition,season}
enum LobbyView {lobby,seasons,schedule,standings,gameGraph}

class Season {
  int id;
  String name;
  Season(this.id,this.name);
  Season.fromJson(Map<String, dynamic> json) :
        id = json[ZugBallField.seasonId],
        name = json[ZugBallField.seasonName];
}

class Schedule {
  final List<ScheduledGame> games;
  final Set<String> playedGames;
  const Schedule(this.games,this.playedGames);
}

class GameEvent {
  final PlayResult result;
  String hitter, pitcher, onFirst, onSecond, onThird, inningHalf;
  int balls, strikes, inning, prevOuts, outs, runs, homeScore, awayScore;

  GameEvent(this.result,this.balls,this.strikes,this.inning, this.inningHalf,
      this.hitter,this.pitcher,this.onFirst,this.onSecond,this.onThird,
      this.prevOuts,this.outs,this.runs,this.homeScore,this.awayScore);
}


class GameModel extends ZugModel {

  bool fetchingData = false;
  LobbyView lobbyView = LobbyView.lobby;
  Season? currentSeason;
  Schedule? currentSchedule;
  List<Season> seasons = [];
  Map<int, Team> teamMap = {};
  SeasonStandings? currentStandings;
  List<GameEvent> gameLog = [];
  MidiManager midiMgr = MidiManager();
  double tempo = .5;

  Game get currentGame => currentArea as Game;

  Game getGame(data) => getOrCreateArea(data) as Game;

  GameModel(super.domain, super.port, super.remoteEndpoint, super.prefs,
      {super.firebaseOptions, super.localServer,super.showServMess,super.javalinServer}) {
    showServMess = true;
    modelName = "ForkBallClient";
    registerEnum(Team.values);
    setOptionFromEnum(GameOptions.team, getOption(GameOptions.team) ??
        Team.boston.asOption(label: "Favorite Team"));
    addFunctions({
      GameMsg.pitchResult: handlePitch,
      GameMsg.guessNotification: handleGuessNotification,
      GameMsg.teamMap : handleTeamMap,
      GameMsg.listSeasons : handleSeasonList,
      GameMsg.scheduleResponse : handleSchedule,
      GameMsg.standingsResponse : handleStandings,
      GameMsg.gameLog : handleGamelog //handleGameLog
    });
    editOption(AudioOpt.music, true);
    checkRedirect("lichess.org");

    midiMgr.audioReady = true;
    midiMgr.muted = false;
    List<MidiAssignment> ensemble = midiMgr.randomEnsemble(List<MidiPerformer>.of(["V1","V2"]));
    midiMgr.load(ensemble).then((v) {
      ZugModel.log.info("*** Loaded Audio ***"); //midiMgr.playNote(ensemble.first.instrument, 0, 72, 255, .5);
    });

  }

  void newExhibitionGame() {
    selectTeam("Home").then((homeTeam) => selectTeam("Away").then((awayTeam) async =>
      areaCmd(ClientMsg.newArea,id: userName.toString(), data: {
        ZugBallField.homeTeam : homeTeam?.abbrev,
        ZugBallField.awayTeam : awayTeam?.abbrev,
        ZugBallField.side : (await getSide()).name
      })
    ));
  }

  Future<void> newSeasonalGame(ScheduledGame game) async {
    areaCmd(ClientMsg.newArea,id: userName.toString(), data: {
      ZugBallField.side : (await getSide()).name,
      ZugBallField.seasonId : currentSeason?.id,
      ZugBallField.seasonSlot : game.seasonSlot - 1, //TODO: why is this off by one?
      ZugBallField.day : game.day //starts at 1
    });
    lobbyView = LobbyView.lobby;
    notifyListeners();
  }

  Future<Side> getSide() async {
    return await ZugDialogs.getIcon("Select Home/Away", [
      const Icon(Icons.home),const Icon(Icons.airplanemode_active)
    ]) == 0 ? Side.home : Side.away;
  }

  @override
  void joinArea(String id) {
    getSide().then((side) {
      areaCmd(ClientMsg.joinArea,data: {
        id: id,
        ZugBallField.side : side.name
      });
    });
  }

  Future<Team?> selectTeam(String side) async {
    if (zugAppNavigatorKey.currentContext != null) {
      return await TeamSelectionDialog.show(side,zugAppNavigatorKey.currentContext!);
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

  void handleGamelog(data) {
    gameLog.clear();
    for (dynamic logData in data as List<dynamic>) {
      PlayResult result = PlayResult.values
          .firstWhere((r) => r.name == logData[ZugBallField.playResult]);
      gameLog.add(GameEvent(
          result,
          logData[ZugBallField.balls],
          logData[ZugBallField.strikes],
          logData[ZugBallField.inning],
          logData[ZugBallField.inningHalf],
          logData[ZugBallField.batter],
          logData[ZugBallField.pitcher],
          logData[ZugBallField.bases]?[ZugBallField.firstBase],
          logData[ZugBallField.bases]?[ZugBallField.secondBase],
          logData[ZugBallField.bases]?[ZugBallField.thirdBase],
          logData[ZugBallField.prevOuts],
          logData[ZugBallField.outs],
          logData[ZugBallField.runs],
          logData[ZugBallField.home],
          logData[ZugBallField.away],
          ));
    }
    setLobbyView(LobbyView.gameGraph);
    playGameLog();
  }

  void playGameLog({meanRev = false}) {
    ZugKey key = const ZugKey(ZugNote.noteA, Scale.majorScale);
    ZugPitch p = ZugPitch(60);

    List<ZugKey> prog = [
      const ZugKey(ZugNote.noteA, Scale.majorScale),
      const ZugKey(ZugNote.noteC, Scale.harmonicMinorScale),
      const ZugKey(ZugNote.noteF, Scale.mixolydianScale),
      const ZugKey(ZugNote.noteA, Scale.majorScale),
    ];
    int chord = 0;
    const int minPitch = 24;
    const int maxPitch = 108;
    const int centerPitch = 60;
    String inningHalf = ZugBallField.topHalf;
    double t = 0;
    for (GameEvent e in gameLog) {
      if (e.inningHalf != inningHalf) {
        if (++chord >= prog.length) chord = 0;
        //key = prog.elementAt(chord);
        key = ZugKey(getRandomNote(), getRandomScale());
        print("Side Change, new key: $key");
      }
      print("Playing: ${e.result.positivity}, current pitch: ${p.pitch}, current note: ${p.note} ");
      midiMgr.playNote(midiMgr.orchMap["V1"], t, p.pitch, 1, .25);
      t += (.25 * tempo);

      int steps = e.result.positivity;
      if (meanRev) {
        int distanceFromCenter = p.pitch - centerPitch;
        if (distanceFromCenter.abs() > 32) { // 3/4 octave
          if ((distanceFromCenter > 0 && steps > 0) || (distanceFromCenter < 0 && steps < 0)) {
            steps = -steps; // Reverse direction
          }
        }
      }

      // Try the move
      ZugPitch testPitch = e.result.endAtBat ? key.getNextPitch(p, steps) : ZugPitch(p.pitch + steps);

      // Hard limit: if it goes out of bounds, reverse
      if (testPitch.pitch > maxPitch || testPitch.pitch < minPitch) {
        steps = -steps.abs(); // Force downward if too high
        if (testPitch.pitch < minPitch) steps = steps.abs(); // Force upward if too low
      }

      p = key.getNextPitch(p, steps);
      inningHalf = e.inningHalf;
    }
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
    currentSchedule = Schedule(games, playedGames);
    lobbyView = LobbyView.schedule;
    fetchingData = false;
  }

  void requestSchedule() {
    send(GameMsg.getSchedule, data:
    { ZugBallField.seasonId : currentSeason?.id });
    fetchingData = true;
    notifyListeners();
  }

  void handleStandings(data) {
    currentStandings = SeasonStandings.fromJson(data);
    lobbyView = LobbyView.standings;
    fetchingData = false;
  }

  void requestStandings() {
    if (currentSeason != null) {
      send(GameMsg.getStandings, data: {
        ZugBallField.seasonId: currentSeason!.id
      });
      fetchingData = true;
      notifyListeners();
    }
  }

  void setLobbyView(LobbyView view) {
    lobbyView = view;
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
