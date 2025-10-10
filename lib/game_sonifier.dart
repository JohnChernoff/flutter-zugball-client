import 'package:forkball/game_model.dart';
import 'package:forkball/zugball_fields.dart';
import 'package:zug_music/sequencer.dart';
import 'package:zug_music/zug_midi.dart';
import 'package:zug_music/zug_music.dart';
import 'game.dart';

class ScoreEvent {
  int runs;
  double t;
  bool home;
  ScoreEvent(this.runs,this.t,this.home);
}

class GameSonifier {
  MidiManager midiMgr = MidiManager();
  double tempo = .5;
  MidiAssignment homeVoice, awayVoice, eventVoice, countVoice, baseVoice;
  final int minPitch = 24, maxPitch = 108, centerPitch = 60;

  GameSonifier({
    homeInstrument = MidiInstrument.cello,
    awayInstrument = MidiInstrument.trombone,
    eventInstrument = MidiInstrument.acousticGuitarNylon,
    countInstrument = MidiInstrument.clarinet,
    baseInstrument = MidiInstrument.englishHorn }) :
        homeVoice = MidiAssignment("homeVoice",homeInstrument,.5),
        awayVoice = MidiAssignment("awayVoice",awayInstrument,.5),
        eventVoice = MidiAssignment("eventVoice",eventInstrument,.5),
        countVoice = MidiAssignment("countVoice",countInstrument,.5),
        baseVoice = MidiAssignment("baseVoice",baseInstrument,.5) {
    midiMgr.audioReady = true;
    midiMgr.muted = false;
    midiMgr.load(List.of([homeVoice,awayVoice,eventVoice, countVoice, baseVoice])).then((v) {
      log("*** Loaded Audio ***"); //midiMgr.playNote(homeVoice.instrument, 0, 60, 2, .25);
    });
  }

  sonifyGameLog(List<GameEvent> gameLog, {homeView = true, playMaster = false}) {
    ZugKey key = const ZugKey(ZugNote.noteA, Scale.majorScale);
    ZugPitch p = ZugPitch(60);

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
    sequencer.tempo = 200;
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

    for (GameEvent e in gameLog) {
      battingSide = Game.getBattingSide(inningHalf: e.inningHalf);

      int newInning = e.inning;
      if (inning != newInning) {
        inning = newInning;
        if (++chord >= prog.length) chord = 0;
        //key = ZugKey(getRandomNote(), getRandomScale());
        key = prog.elementAt(chord);
        log("New inning: $inning, new key: $key");
      }

      Count newCount = Count(e.balls, e.strikes);
      if (!count.eq(newCount)) {
        count = newCount;
        int p = key.getNextPitch(ZugPitch(key.getRootPitch(5)), getCountSteps(count)).pitch;
        //log("Count pitch: $p");
        countTrack.addEventAutoHold(countVoice.instrument, p, t, .5);
      }

      Bases newBases = Bases(e.onFirst.isNotEmpty, e.onSecond.isNotEmpty, e.onThird.isNotEmpty);
      if (!bases.eq(newBases)) {
        bases = newBases;
        int p = key.getNextPitch(ZugPitch(key.getRootPitch(4)), getBasesSteps(bases)).pitch;
        //log("Bases pitch: $p");
        baseTrack.addEventAutoHold(baseVoice.instrument, p, t, .5);
        log("New Bases: ${bases.toString()}");
      }

      if (e.runs > 0) {
        if (battingSide == Side.away) {
          awayScore += e.runs;
          awayScoreTrack.addEventAutoHold(homeVoice.instrument, key.getRootPitch(3) + awayScore, t, .25);
        } else {
          homeScore += e.runs;
          homeScoreTrack.addEventAutoHold(awayVoice.instrument, key.getRootPitch(3) + homeScore, t, .25);
        }
      }

      double dur = .25 * tempo; //calcDur(e) * tempo;
      if (playMaster) {
        int steps = calcSteps(e,key,p);
        p = key.getNextPitch(p, steps);
        log("Steps: $steps, pitch: ${p.pitch}, note: ${p.note}, dur: $dur ");
        masterTrack.addEvent(eventVoice.instrument, p.pitch, t, dur, .5);
      }
      t += dur;
    }

    sequencer.play();
  }

  double calcDur(GameEvent e) {
    if (e.guessedLocation && e.guessedPitch) {
      return .66;
    } else if (e.guessedLocation) {
      return .5;
    }
    else if (e.guessedPitch) {
      return .33;
    }
    return .25;
  }

  int calcSteps(GameEvent e, ZugKey key, ZugPitch p, {homeView = true}) {
    int steps = (homeView ^ (e.inningHalf == ZugBallField.topHalf))
        ? e.result.positivity : -e.result.positivity;

    // Try the move
    ZugPitch testPitch = e.result.endAtBat ? key.getNextPitch(p, steps) : ZugPitch(p.pitch + steps);

    // Hard limit: if it goes out of bounds, reverse
    if (testPitch.pitch > maxPitch || testPitch.pitch < minPitch) {
      steps = -steps.abs(); // Force downward if too high
      if (testPitch.pitch < minPitch) steps = steps.abs(); // Force upward if too low
    }

    return steps;
  }

  int getCountSteps(Count count) {
    if (count.balls == 0 && count.strikes == 0) return 0;
    if (count.balls == 1 && count.strikes == 0) return 1;
    if (count.balls == 2 && count.strikes == 0) return 2;
    if (count.balls == 3 && count.strikes == 0) return 3;
    if (count.balls == 1 && count.strikes == 1) return 4;
    if (count.balls == 2 && count.strikes == 1) return 5;
    if (count.balls == 3 && count.strikes == 1) return 6;
    if (count.balls == 1 && count.strikes == 2) return 7;
    if (count.balls == 2 && count.strikes == 2) return 8;
    if (count.balls == 3 && count.strikes == 2) return 9;
    return 10;
  }

  int getBasesSteps(Bases bases) {
    if (bases.first && !bases.second && !bases.third) return 1;
    if (!bases.first && bases.second && !bases.third) return 2;
    if (!bases.first && !bases.second && bases.third) return 3;
    if (bases.first && bases.second && !bases.third) return 4;
    if (bases.first && !bases.second && bases.third) return 5;
    if (!bases.first && bases.second && bases.third) return 6;
    if (bases.first && bases.second && bases.third) return 7;
    return 0;
  }
}
