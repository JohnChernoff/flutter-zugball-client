enum PlayResult { //add errors/stolen bases/balks
  exception(false,false,false,0),
  single(true,false,true,2),
  dbl(true,false,true,5),
  triple(true,false,true,7),
  homerun(true,false,true,8),
  strikeout(false,false,true,-2),
  walk(false,false,true,2),
  ball(true,false,false,1),
  swingAndMiss(false,false,false,-1),
  calledStrike(false,false,false,-1),
  foul(false,false,false,0),
  groundout(false,false,true,-2),
  buntSacrifice(false,true,true,0),
  buntHit(true,false,true,2),
  buntOut(false,false,true,-2),
  popOut(false,false,true,-2),
  sacFly(false,true,true,0),
  lineOut(false,false,true,-2);

  final bool hit, sacrifice, endAtBat;
  final int positivity;

  const PlayResult(this.hit, this.sacrifice, this.endAtBat, this.positivity);

  static PlayResult parsePlayResult(String? eventType) {
    if (eventType == null || eventType.isEmpty) return PlayResult.exception;
    switch (eventType.toLowerCase()) {
      case 'single': return PlayResult.single;
      case 'double': return PlayResult.dbl;
      case 'triple': return PlayResult.triple;
      case 'home_run': return PlayResult.homerun;
      case 'strikeout':
      case 'strikeout_double_play': return PlayResult.strikeout;
      case 'walk':
      case 'intent_walk':
      case 'hit_by_pitch': return PlayResult.walk;
      case 'groundout':
      case 'force_out':
      case 'field_out': return PlayResult.groundout;
      case 'flyout': return PlayResult.popOut;
      case 'pop_out': return PlayResult.popOut;
      case 'lineout': return PlayResult.lineOut;
      case 'sac_fly': return PlayResult.sacFly;
      case 'sac_bunt': return PlayResult.buntSacrifice;
      case 'bunt_groundout': return PlayResult.buntOut;
      case 'bunt_single': return PlayResult.buntHit;
      case 'field_error':
      case 'balk':
      case 'wild_pitch':
      case 'passed_ball': return PlayResult.exception;
      default: return PlayResult.exception;
    }
  }
}
