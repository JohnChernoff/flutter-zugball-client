import 'package:forkball/game_model.dart';
import 'package:zug_music/sequencer.dart';
import 'package:zug_music/zug_music.dart';
import 'game.dart';
import 'game_event.dart';
import 'game_sonifier.dart';
import 'dart:math';

/// Extends GameSonifier by adding "momentum" tracking to drive key,
/// tempo, and dynamics changes across the game.
class MomentumGameSonifier extends GameSonifier {
  double _momentum = 0;        // rolling “heat” measure
  double _momentumDecay = 0.9; // decays slowly between events
  double _momentumSensitivity = 0.5; // how strongly events affect momentum
  final Random _rand = Random();

  MomentumGameSonifier({
    super.homeInstrument,
    super.awayInstrument,
    super.eventInstrument,
    super.countInstrument,
    super.baseInstrument,
  });

  @override
  sonifyGameLog(GameLog gameLog, {homeView = true, playMaster = false}) {
    List<ZugKey> prog = [
      const ZugKey(ZugNote.noteA, Scale.majorScale),
      const ZugKey(ZugNote.noteDb, Scale.majorScale),
      const ZugKey(ZugNote.noteF, Scale.majorScale),
      const ZugKey(ZugNote.noteAb, Scale.majorScale),
      const ZugKey(ZugNote.noteC, Scale.majorScale),
      const ZugKey(ZugNote.noteE, Scale.majorScale),
    ];

    int chord = 0;
    final sequencer = MidiSequencer(midiMgr);
    final masterTrack = MidiTrack('master');
    final homeScoreTrack = MidiTrack('home_score');
    final awayScoreTrack = MidiTrack('away_score');
    final countTrack = MidiTrack('count');
    final baseTrack = MidiTrack('bases');
    sequencer.addTrack(masterTrack);
    sequencer.addTrack(homeScoreTrack);
    sequencer.addTrack(awayScoreTrack);
    sequencer.addTrack(countTrack);
    sequencer.addTrack(baseTrack);

    double t = 0;
    int homeScore = 0, awayScore = 0, inning = 0;
    Count count = Count(0,0);
    Side battingSide = Side.away;
    Bases bases = Bases(false,false,false);

    // Precompute basic momentum (windowed runs)
    final baseMomentum = computeMomentum(gameLog.log);
    ZugKey key = prog.first;

    for (int i = 0; i < gameLog.log.length; i++) {
      final e = gameLog.log[i];

      // Update momentum
      _updateMomentum(e);

      battingSide = Game.getBattingSide(inningHalf: e.inningHalf);

      // Key change at inning start (with momentum influence)
      if (inning != e.inning) {
        inning = e.inning;
        chord = (chord + 1) % prog.length;
        ZugKey baseKey = prog[chord];
        key = _getKeyFromMomentum(_momentum, inning);
        log("New inning: $inning, new key: $key (base ${baseKey.keyNote})");
      }

      // Count changes
      Count newCount = Count(e.balls, e.strikes);
      if (!count.eq(newCount)) {
        count = newCount;
        int p = key.getNextPitch(ZugPitch(key.getRootPitch(5)), getCountSteps(count)).pitch;
        countTrack.addEventAutoHold(countVoice.instrument, p, t, 0.5);
      }

      // Base changes
      Bases newBases = Bases(e.onFirst.isNotEmpty, e.onSecond.isNotEmpty, e.onThird.isNotEmpty);
      if (!bases.eq(newBases)) {
        bases = newBases;
        int p = key.getNextPitch(ZugPitch(key.getRootPitch(4)), getBasesSteps(bases)).pitch;
        baseTrack.addEventAutoHold(baseVoice.instrument, p, t, 0.5);
      }

      // Runs scored
      if (e.runs > 0) {
        if (battingSide == Side.away) {
          awayScore += e.runs;
          awayScoreTrack.addEventAutoHold(
              homeVoice.instrument,
              key.getRootPitch(3) + awayScore,
              t,
              0.25
          );
        } else {
          homeScore += e.runs;
          homeScoreTrack.addEventAutoHold(
              awayVoice.instrument,
              key.getRootPitch(3) + homeScore,
              t,
              0.25
          );
        }
      }

      // Master track: tension, momentum, clutch
      double dur = 0.25 / _getTempoFactor(_momentum);
      if (playMaster) {
        int steps = e.tension; // outs + runners
        ZugPitch pitch = key.getNextPitch(ZugPitch(centerPitch), steps);

        double velocity = _getVelocity(_momentum);

        masterTrack.addEvent(eventVoice.instrument, pitch.pitch, t, dur, velocity);

        // Late-inning clutch motif
        if (e.clutch(e.homeScore, e.awayScore)) {
          baseTrack.addEvent(baseVoice.instrument, centerPitch + 12, t, dur, velocity);
        }
      }

      t += dur;
    }

    sequencer.play();
  }

  // --------------------------------------------------------------------------
  // MOMENTUM SYSTEM
  // --------------------------------------------------------------------------

  void _updateMomentum(GameEvent e) {
    _momentum *= _momentumDecay;

    double delta = e.runs.toDouble();
    if (e.result.positivity != 0) delta += e.result.positivity * 0.2;
    if (e.outs > 0) delta -= e.outs * 0.15;

    _momentum += delta * _momentumSensitivity;
    _momentum = _momentum.clamp(-8, 8);
  }

  ZugKey _getKeyFromMomentum(double m, int inning) {
    int offset = m.round();
    Scale scale = m >= 0 ? Scale.majorScale : Scale.melodicMinorScale;
    ZugNote root = ZugNote.values[(ZugNote.noteC.index + offset) % ZugNote.values.length];
    return ZugKey(root, scale);
  }

  double _getTempoFactor(double m) {
    return 1.0 + (m / 10.0);
  }

  double _getVelocity(double m) {
    return 0.5 + (m.abs() / 8.0) * 0.5;
  }

  List<int> computeMomentum(List<GameEvent> events, {int window = 3}) {
    List<int> momentum = List.filled(events.length, 0);
    for (int i = 0; i < events.length; i++) {
      int runSum = 0;
      for (int j = i; j >= 0 && j > i - window; j--) {
        runSum += events[j].runs;
      }
      momentum[i] = runSum;
    }
    return momentum;
  }
}
