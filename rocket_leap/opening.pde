int g1=0;
void opening(){
  if (x[5] == 0.0) {
    background(0);
    textSize(50);
    fill(255, 255, 0, 100 + aaa / 2);
    textAlign(CENTER);
    if(hands.count()==0) text("Put Your Hand", w2, h2+200);
    if(hands.count()>0) text("Slide Your Hand", w2, h2+200);
    textSize(80);
    fill(255);
    text("The World is Nothing", w2, h2);
  }
  else if (x[5] == 1.0) {
    textAlign(CENTER);
    background(0);
    textSize(80);
    fill(255);
    text("Let there be...", w2, h2);
    textAlign(LEFT);
  }
  else if (x[5] == 2.0) {
    if (g1<256) {
      background(g1);
      textSize(80);
      fill(255);
      textAlign(CENTER);
      text("Light!!", w2, h2);
      textAlign(LEFT);
      g1++;
    }
    else if (g1 >= 256 && g1<511) {
      background(511 - g1);
      g1++;
    }
    else if (g1 == 511) {
      replace();
//      earth = new Earth();
      state3 = 1; //ゲーム状態へ
    }
  }
}