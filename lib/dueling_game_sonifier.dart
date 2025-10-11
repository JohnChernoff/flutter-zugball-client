import 'dart:math';
import 'package:forkball/game_model.dart';
import 'package:forkball/zugball_fields.dart';
import 'package:zug_music/sequencer.dart';
import 'package:zug_music/zug_midi.dart';
import 'package:zug_music/zug_music.dart';
import 'game.dart';
import 'game_event.dart';
import 'momentum_game_sonifier.dart';

/// Expands the MomentumGameSonifier to track and musically contrast
/// separate home/away momentum in stereo “duel” fashion.
class DuelingMomentumSonifier extends MomentumGameSonifier {
  double homeMomentum = 0;
  double awayMomentum = 0;

  final double decay = 0.9;
  final double sensitivity = 0.5;
  final Random rand = Random();

  DuelingMomentumSonifier({
    super.homeInstrument,
    super.awayInstrument,
    super.eventInstrument,
    super.countInstrument,
    super.baseInstrument,
  });

  @override
  sonifyGameLog(gameLog, {homeView = true, playMaster = false}) {
    final sequencer = MidiSequencer(midiMgr);
    final homeTrack = MidiTrack('home');
    final awayTrack = MidiTrack('away');
    final tensionTrack = MidiTrack('tension');
    sequencer.addTrack(homeTrack);
    sequencer.addTrack(awayTrack);
    sequencer.addTrack(tensionTrack);

    double t = 0;
    double baseTempo = tempo;
    int inning = 0;

    ZugKey homeKey = const ZugKey(ZugNote.noteC, Scale.majorScale);
    ZugKey awayKey = const ZugKey(ZugNote.noteG, Scale.majorScale);
    ZugPitch homePitch = ZugPitch(60);
    ZugPitch awayPitch = ZugPitch(60);

    for (final e in gameLog.log) {
      // Update inning/key transitions
      if (e.inning != inning) {
        inning = e.inning;
        // Inning change = brief “reset” chord for both sides
        tensionTrack.addEventAutoHold(eventVoice.instrument,
            homeKey.getRootPitch(3), t, .4);
        tensionTrack.addEventAutoHold(eventVoice.instrument,
            awayKey.getRootPitch(3) + 4, t, .4);
      }

      // Determine batting side
      final side = Game.getBattingSide(inningHalf: e.inningHalf);

      // --- Update momentum for both sides ---
      _updateMomentum(side, e);

      // Derive harmonic & tempo factors from each momentum
      homeKey = _getKeyFromMomentum(homeMomentum, homeKey);
      awayKey = _getKeyFromMomentum(awayMomentum, awayKey);

      final homeTempo = baseTempo * _getTempoFactor(homeMomentum);
      final awayTempo = baseTempo * _getTempoFactor(awayMomentum);
      final homeVel = _getVelocity(homeMomentum);
      final awayVel = _getVelocity(awayMomentum);

      // --- Play event ---
      final double dur = .25 * baseTempo;
      if (side == Side.home) {
        int steps = calcSteps(e, homeKey, homePitch, homeView: homeView);
        homePitch = homeKey.getNextPitch(homePitch, steps);
        homeTrack.addEvent(
            homeVoice.instrument, homePitch.pitch, t, dur, homeVel);
      } else {
        int steps = calcSteps(e, awayKey, awayPitch, homeView: homeView);
        awayPitch = awayKey.getNextPitch(awayPitch, steps);
        awayTrack.addEvent(
            awayVoice.instrument, awayPitch.pitch, t, dur, awayVel);
      }

      // --- Ambient tension background ---
      double tension = (homeMomentum - awayMomentum).abs();
      if (tension > 4 && rand.nextDouble() < 0.4) {
        int base = 48 + rand.nextInt(6);
        tensionTrack.addEventAutoHold(
            baseVoice.instrument, base, t, 0.2 + (tension / 10));
      }

      t += dur * ((side == Side.home) ? homeTempo : awayTempo);
    }

    // stereo spread (if supported)
    //homeTrack.pan = 0.2; // left
    //awayTrack.pan = 0.8; // right

    sequencer.play();
  }

  // --------------------------------------------------------------------------
  // MOMENTUM ENGINE (dual)
  // --------------------------------------------------------------------------

  void _updateMomentum(Side battingSide, GameEvent e) {
    homeMomentum *= decay;
    awayMomentum *= decay;

    double delta = e.runs.toDouble();
    if (e.result.positivity != 0) delta += e.result.positivity * 0.2;
    if (e.outs > 0) delta -= e.outs * 0.15;
    delta *= sensitivity;

    if (battingSide == Side.home) {
      homeMomentum += delta;
    } else {
      awayMomentum += delta;
    }

    // Clamp
    homeMomentum = homeMomentum.clamp(-8, 8);
    awayMomentum = awayMomentum.clamp(-8, 8);
  }

  ZugKey _getKeyFromMomentum(double m, ZugKey prevKey) {
    // shift tonal center gradually
    int offset = m.round();
    Scale scale = m >= 0 ? Scale.majorScale : Scale.melodicMinorScale;
    int newRootIndex =
        (prevKey.keyNote.index + offset + ZugNote.values.length) %
            ZugNote.values.length;
    return ZugKey(ZugNote.values[newRootIndex], scale);
  }

  double _getTempoFactor(double m) => 1.0 + (m / 10.0);
  double _getVelocity(double m) => 0.5 + (m.abs() / 8.0) * 0.5;
}
