float fingerReplay(float a,float b,float e,int Re){
  float fx, fy, x, y; //指の位置
  int replayX = 700;
  int replayY = (int)100;
  fx = width/250*a;
  fy = height/100*b;
  x=fx+ w2; //左上が原点
  y=fy+ h2;
  if(replayX-90<x && x<replayX+90 && replayY-30<y && y<replayY+30){
    distanceReplay=1.0;
  }else{
    distanceReplay=0.0;
  }
  if(distanceReplay==1.0){
    if(e==1.0&state4==0){
      stroke(255,0,0);
      strokeWeight(5);
      line(x, y+16, x, y-16);    //撃つ方向
      line(x-16, y, x+16, y);    //撃つ方向
      timeRestart=millis();
      state4=1;
      return 0.0;
    }else if(e==1.0&&state4==1){
      stroke(0,255,0);
      strokeWeight(5);
      line(x, y+16, x, y-16);    //撃つ方向
      line(x-16, y, x+16, y);    //撃つ方向
      timeRefinish=millis();
      if(timeRefinish-timeRestart>2000){
        timeRestart=0.0;
        timeRefinish=0.0;
        state4=0;
        return 1.0;
      }else{
        return 0.0;
      }
    }else{
      stroke(255,0,0);
      strokeWeight(5);
      line(x, y+16, x, y-16);    //撃つ方向
      line(x-16, y, x+16, y);    //撃つ方向
      timeRestart=0.0;
      timeRefinish=0.0;
      state4=0;
      return 0.0;
    }
  }else{
    stroke(0,0,255);
    strokeWeight(5);
    line(x, y+16, x, y-16);    //撃つ方向
    line(x-16, y, x+16, y);    //撃つ方向
    timeRestart=0.0;
    timeRefinish=0.0;
    state4=0;
    return 0.0;
  }
}
