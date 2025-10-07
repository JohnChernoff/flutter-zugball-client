enum PlayResult { //add errors/stolen bases/balks
  exception(false,false,false,0),
  single(true,false,true,3),
  dbl(true,false,true,3),
  triple(true,false,true,4),
  homerun(true,false,true,5),
  strikeout(false,false,true,-2),
  walk(false,false,true,2),
  ball(true,false,false,1),
  swingAndMiss(false,false,false,-1),
  calledStrike(false,false,false,-1),
  foul(false,false,false,0),
  groundout(false,false,true,-2),
  buntSacrifice(false,true,true,0),
  buntHit(true,false,true,1),
  buntOut(false,false,true,-2),
  popOut(false,false,true,-2),
  sacFly(false,true,true,0),
  lineOut(false,false,true,-2);

  final bool hit, sacrifice, endAtBat;
  final int positivity;

  const PlayResult(this.hit, this.sacrifice, this.endAtBat, this.positivity);
}
