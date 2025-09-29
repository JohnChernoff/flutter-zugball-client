import 'package:forkball/game_model.dart';
import 'package:forkball/schedule.dart';
import 'package:forkball/seasons.dart';
import 'package:forkball/standings.dart';
import 'package:zugclient/lobby_page.dart';
import 'package:flutter/material.dart';
import 'package:forkball/teams.dart';
import 'package:forkball/zugball_fields.dart';
import 'package:zugclient/zug_area.dart';

import 'matchup_widget.dart';

class ForkLobby extends LobbyPage {

  const ForkLobby(super.model, {super.seekButt = false, super.zugChat, super.key});

  @override
  List<CommandButtonData> getExtraCmdButtons(BuildContext context) {
    List<CommandButtonData> extras = super.getExtraCmdButtons(context);
    if (!model.isGuest()) {
      extras.add(CommandButtonData("Seasons", Colors.green, Icons.access_time_outlined,
              () => (model as GameModel).setLobbyView(LobbyView.seasons)));
    }
    extras.add(CommandButtonData("Schedule", Colors.purple, Icons.calendar_month,
            () => (model as GameModel).requestSchedule()));
    extras.add(CommandButtonData("Standings", model.isGuest() ? Colors.green : Colors.cyan, Icons.add_chart,
            () => (model as GameModel).requestStandings()));
    return extras;
  }

  @override
  CommandButtonData getCreateButton({Color normCol = Colors.greenAccent}) {
    return CommandButtonData("New Exhibition Game", normCol, Icons.sports_baseball, (model as GameModel).newExhibitionGame);
  }

  @override
  Widget? selectorWidget() {
    GameModel gameModel = model as GameModel;
    if (gameModel.fetchingData) return const SizedBox.shrink();
    if (gameModel.lobbyView == LobbyView.lobby) return super.selectorWidget();
    return ElevatedButton(onPressed: () => gameModel.setLobbyView(LobbyView.lobby), child: const Text("Return to Lobby"));
  }

  @override
  Widget selectedArea(BuildContext context, {Color? bkgCol, Color? txtCol, Iterable? occupants}) {
    GameModel gameModel = model as GameModel;
    if (gameModel.fetchingData) return const Text("Fetching data...");
    return switch(gameModel.lobbyView) {
      LobbyView.lobby => MatchupWidget(gameModel),
      LobbyView.seasons => SeasonWidget(gameModel),
      LobbyView.schedule => SeasonScheduleWidget(model : gameModel,
          selectedTeam: model.getOption(GameOptions.team)?.getEnum(Team.values) as Team),
      LobbyView.standings => StandingsWidget(model: gameModel),
    };
  }

}
