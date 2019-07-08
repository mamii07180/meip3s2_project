float timestart=0.0;
float timelag=2000;
int state1=0;
boolean big = false;
float n, m;

void drawFingerTip(float a, float b, float d, float e, int posi) {
  float fx, fy, x, y; //指の位置
  int trisize = 30;      
  float angle = 0;
  float rchange = 5;
  fx = width / 250 * a;
  fy = height / 100 * b;
  x = fx + w2 - 100; //左上が原点、右にちょいずれ
  y = fy + h2;
  if (posi == 1) { //手の位置がいい感じだったら
    if (fx <= -w2 || fx >= w2 || fy <= -h2 || fy >= h2) { //画面の外にはみでてたら
      if (fx <= -w2) {
        x = trisize;
        angle = 3 * PI / 2;
      }
      if (fx >= w2) {
        x = width - trisize;
        angle = PI / 2;
      }
      if (fy <= -h2)    y = trisize;
      if (fy >= h2) {
        y = height - trisize;
        angle = PI;
      }
      stroke(255);
      pushMatrix();
      translate(x, y);//円の中心に座標を合わせます
      rotate(angle);
      drawTriangle(0, 0, trisize);  // 横の位置、縦の位置、円の半径
      popMatrix();
    }
    else { //画面内だったら
      timelag = millis()-timestart;
      if(timelag>=2000){ //タイムラグが2000以上だったら
        float dis = dist(myself.loc.x, myself.loc.y, x, y); //ロケットとの距離
        float edis = dist(earth.loc.x, earth.loc.y, x, y); //地球との距離
        if (dis <= 100) { //ロケットとカーソルの位置が近すぎたら
          noFill();
          strokeWeight(5);
          stroke(255, 0, 0);
          ellipse(myself.loc.x, myself.loc.y, 2 * dis, 2 * dis);
          timestart = millis()-2000;
        }
        else if (edis <= 100) { //地球とカーソルの位置が近すぎたら
          noFill();
          strokeWeight(5);
          stroke(255, 0, 0);
          ellipse(earth.loc.x, earth.loc.y, 2 * edis, 2 * edis);
          timestart = millis()-2000;
        }
        else {
          switch(state1){ //state1で指の状態遷移
            case 0 :
              if(timelag>5000){
                big =true;
              }
              if (e==1.0) {
                state1=1;
                rchange = 5;
              }
              break;

            case 1 : //いっかい指のばしたら
              if (e==0){
                n = x; //中心点
                m = y; //中心点
                state1 = 2; //指まげたら遷移
              }
              break;

            case 2 : //曲がってる
              if (e==0){
                noFill();
                strokeWeight(5);
                stroke(0, 255, 0);
                ellipse(n, m, d, d);
              } else { //2回目にゆびのばしたら
                ene_number++;
                if (big) { //big=trueなら
                  println("big OK");
                  enemies.add(new Enemy(n, m, d, ene_number, 1)); //dは指の間の距離
                  enecountb++;
                } else {
                  enemies.add(new Enemy(n, m, d, ene_number, 0));
                  enecount++;
                }
                println(ene_number);
                int dead_ene_num = ene_number % 15;
                Enemy dead = enemies.get(dead_ene_num);
                if (!dead.isDead) {
                  dead.isDead = true;
                  enemies.set(dead_ene_num, dead);
                  client.write(4 + " " + dead_ene_num + " " + 0 + "\n"); //死滅個体
                }
                state1 = 3;
              }
              break;

            case 3 :
              if(e==0){ //2回目に指まげたら
                timestart = millis(); //星を作った時間
                big = false;
                state1 = 0;
              }
              break;
          } 
          if(big) {
            stroke(255, aaa, 0);
            if(timelag<5500){
                ellipse(x, y, rchange, rchange);
                rchange = rchange + 2;
            }
          }
          else  stroke(255 - aaa, 255, aaa);
          strokeWeight(5);
          line(x, y + 16, x, y - 16);    //撃つ方向
          line(x - 16, y, x + 16, y);    //撃つ方向
        }
      } else { //ラグが2000以下だったら
        strokeWeight(5);
        line(x, y + 16, x, y - 16);    //撃つ方向
        line(x - 16, y, x + 16, y);    //撃つ方向
        float rad = (millis()-timestart)/2000*2*PI;
        noFill();
        arc( x, y, 100, 100, PI/2, rad+PI/2);
      }
    }
  }
  else { //positionよくなかったら
    fx = 0;
    fy = 0;
    state1 = 0;
    timestart = millis()-2000;

  }
}
