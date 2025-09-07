import 'package:flutter/material.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient_template/zugball_fields.dart';
import 'ballpark.dart';
import 'game.dart';
import 'game_model.dart';

class GamePage extends StatefulWidget {

  final GameModel model;
  const GamePage(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<GamePage> {

  @override
  void initState() {
    super.initState();
    widget.model.areaCmd(ClientMsg.setDeaf,data:{fieldDeafened:false});
    widget.model.areaCmd(ClientMsg.updateArea);
  }

  @override
  Widget build(BuildContext context) {
    Game cg = widget.model.currentGame;
    return Column(children: [
      if (cg.exists) Row(children: [
        Expanded(flex: 2, child: Ballpark(
          homeTeam: cg.upData[ZugBallField.homeTeam]?[ZugBallField.teamCity] ?? "?",
          awayTeam: cg.upData[ZugBallField.awayTeam]?[ZugBallField.teamCity] ?? "?",
          homeRuns: cg.upData[ZugBallField.homeTeam]?[ZugBallField.runs] ?? 0,
          awayRuns: cg.upData[ZugBallField.awayTeam]?[ZugBallField.runs] ?? 0,
          inning: cg.upData[ZugBallField.inning] ?? 0,
          inningHalf: cg.upData[ZugBallField.inningHalf] ?? "TOP",
          outs:  cg.upData[ZugBallField.outs] ?? 0,
          balls: cg.upData[ZugBallField.balls] ?? 0,
          strikes: cg.upData[ZugBallField.strikes] ?? 0,
          firstBaseRunner: cg.upData[ZugBallField.firstBase] ?? "",
          secondBaseRunner: cg.upData[ZugBallField.secondBase] ?? "",
          thirdBaseRunner: cg.upData[ZugBallField.thirdBase] ?? "",
          batterName: cg.upData[ZugBallField.atBat]?[ZugBallField.lastName] ?? "",
          pitcherName: cg.upData[ZugBallField.pitching]?[ZugBallField.lastName] ?? "",
        )),
        Expanded(flex: 1, child: ColoredBox(color: Colors.cyan,child: Column(children: [
          Text("Batter: ${cg.upData[ZugBallField.atBat]?[ZugBallField.firstName]} ${cg.upData[ZugBallField.atBat]?[ZugBallField.lastName]}"),
          Text("Avg: ${(cg.upData[ZugBallField.atBat]?[ZugBallField.battingAvg] ?? 0) * 1000} "),
          Text("OPS: ${(cg.upData[ZugBallField.atBat]?[ZugBallField.ops] ?? 0) * 1000} "),
          ])))
      ]),
      Expanded(child: SizedBox(child: Row(children: [
        Column(children: [
          pitchInfoBox(cg),
          Expanded(child: AspectRatio(aspectRatio: cg.zoneWidth/cg.zoneHeight,
              child: PitchLocationWidget(widget.model))),
        ]),
        Expanded(flex: 1, child: PitchSelectionWidget(widget.model)),
        Expanded(flex: 2, child: ZugChat(widget.model))
      ],))),
    ],);
  }

  Widget pitchInfoBox(Game cg) {
    return ColoredBox(color: Colors.white, child: Column(children: [
      Text("${cg.lastPitch}"),
      Text("MPH: ${cg.lastPitchSpeed}")
    ]));
  }
}

class PitchLocationWidget extends StatefulWidget {
  final GameModel model;
  const PitchLocationWidget(this.model,{super.key});

  @override
  State<StatefulWidget> createState() => _PitchLocationWidgetState();
}

class _PitchLocationWidgetState extends State<PitchLocationWidget> {
  double _px = .5, _py = .5;

  @override
  Widget build(BuildContext context) {
    Game cg = widget.model.currentGame;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate buffer the same way as in Game class
        double zoneWidth = cg.zoneWidth.toDouble();
        double zoneHeight = cg.zoneHeight.toDouble();
        double ballBuff = cg.ballBuff;

        double totalGameWidth = zoneWidth + (zoneWidth * ballBuff * 2);
        double totalGameHeight = zoneHeight + (zoneHeight * ballBuff * 2);

        // Map game dimensions to UI dimensions
        double strikeZoneWidth = (zoneWidth / totalGameWidth) * constraints.maxWidth;
        double strikeZoneHeight = (zoneHeight / totalGameHeight) * constraints.maxHeight;
        double bufferX = (zoneWidth * ballBuff / totalGameWidth) * constraints.maxWidth;
        double bufferY = (zoneHeight * ballBuff / totalGameHeight) * constraints.maxHeight;

        return GestureDetector(
          onTapDown: (TapDownDetails details) {
            final localPosition = details.localPosition;
            setState(() {
              _px = (localPosition.dx / constraints.maxWidth);
              _py = (localPosition.dy / constraints.maxHeight);
            });
            cg.setSelectedPitchLocation(_px, _py);
          },
          child: Stack(children: [
            // Red background (ball area)
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.red,
            ),
            // Blue strike zone
            Positioned(
              left: bufferX,
              top: bufferY,
              child: Container(
                width: strikeZoneWidth,
                height: strikeZoneHeight,
                color: Colors.blue,
              ),
            ),
            // Last Pitch
            Positioned(
              left: constraints.maxWidth * cg.getRatioX(cg.lastPitchLocation?.dx) - 12,
              top: constraints.maxHeight * cg.getRatioY(cg.lastPitchLocation?.dy) - 12,
              child: const Icon(Icons.sports_baseball, color: Colors.white),
            ),
            // Crosshair
            Positioned(
              left: constraints.maxWidth * _px - 12,
              top: constraints.maxHeight * _py - 12,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ]),
        );
      },
    );
  }
}

class PitchSelectionWidget extends StatefulWidget {
  final GameModel model;
  const PitchSelectionWidget(this.model,{super.key});

  @override
  State<StatefulWidget> createState() => _PitchSelectionWidgetState();
}

class _PitchSelectionWidgetState extends State<PitchSelectionWidget> {
  String? _selectedPitch;

  @override
  Widget build(BuildContext context) {
    Game cg =  widget.model.currentGame;
    UniqueName homeMgr = UniqueName.fromData(cg.upData[ZugBallField.homeTeam]?[ZugBallField.manager]);
    bool userHomeTeam = (homeMgr.eq(widget.model.userName));
    bool batting = cg.upData[ZugBallField.inningHalf] == "bottom" && userHomeTeam;
    List<dynamic> pList = cg.upData[ZugBallField.pitching]?[ZugBallField.pitchList] ?? [];

    return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.green),
        child: RadioGroup<String>(
            groupValue: _selectedPitch,
            onChanged: (String? value) {
              cg.selectedPitch = value;
              setState(() {
                _selectedPitch = value;
              });
            },
            child: Column(children: [
              Text("Currently ${batting ? "Batting" : "Pitching"}"),
              ElevatedButton(
                  onPressed: () => widget.model.areaCmd(GameMsg.nextPitch,data: {
                    ZugBallField.pitchType : cg.selectedPitch,
                    ZugBallField.locX : cg.selectedPitchLocation.dx,
                    ZugBallField.locY : cg.selectedPitchLocation.dy,
                  }),
                  child: const Text("Submit")),
              Expanded(child: ListView(
                  scrollDirection: Axis.vertical,
                  children: List.generate(pList.length, (i) {
                    String pitchType = pList.elementAt(i)[ZugBallField.pitchType];
                    return Row(children: [
                      Radio<String>(value: pitchType),
                      Text(pitchType)
                    ]);
                  })
              ))
            ])
        )
    );
  }
}
