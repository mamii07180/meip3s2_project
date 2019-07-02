float timelag=0;
void drawFingerTip(float a, float b, float d, float e, int posi) {
  float fx, fy, x, y; //指の位置
  boolean big = false;
  fx = width / 250 * a;
  fy = height / 100 * b;
  x = fx + w2 - 100; //左上が原点、右にちょいずれ
  y = fy + h2;
  if (posi == 1) { //手の位置がいい感じだったら
    timelag = millis()-timestart;
    if (fx <= -w2 || fx >= w2 || fy <= -h2 || fy >= h2) { //画面の外にはみでてたら
      float angle = 0;
      int trisize = 30;
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
      timestart = -2000;
    }
    else { //画面内だったら
      if(statelag){ //タイムラグが2000以上だったら
        float dis = dist(myself.loc.x, myself.loc.y, x, y); //ロケットとの距離
        float edis = dist(earth.loc.x, earth.loc.y, x, y); //地球との距離
        if (dis <= 100) { //ロケットとカーソルの位置が近すぎたら
          noFill();
          strokeWeight(5);
          stroke(255, 0, 0);
          ellipse(myself.loc.x, myself.loc.y, 2 * dis, 2 * dis);
        }
        else if (edis <= 100) { //地球とカーソルの位置が近すぎたら
          noFill();
          strokeWeight(5);
          stroke(255, 0, 0);
          ellipse(earth.loc.x, earth.loc.y, 2 * edis, 2 * edis);
        }
        else {
          switch(state1){ //state1で指の状態遷移
            case 0 :
              if (e==1.0) {
                n = x; //中心点
                m = y; //中心点
                state1=1;
                if(timelag>=5000){
                  println("big");
                  big =true;
                }
              }
              break;

            case 1 : //いっかい指のばしたら
              if (e==0){
                state1 = 2; //指まげたら遷移
              }
              break;

            case 2 : //曲がってる
              if (e==0){
                println("OK2");
                  noFill();
                strokeWeight(5);
                stroke(0, 255, 0);
                ellipse(n, m, d, d);
              } else if (e==1){ //2回目にゆびのばしたら
                ene_number++;
                if (big) { //big=trueなら
                  enemies.add(new Enemy(n, m, d, ene_number, 1)); //dは指の間の距離
                } else {
                  enemies.add(new Enemy(n, m, d, ene_number, 0));
                }
                int dead_ene_num = ene_number - 15;
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
                state1 = 0;
                timestart = millis(); //星を作った時間
                statelag = false;
              }
              break;
          } 
          if(big) stroke(255 - aaa, 255, aaa);
          else  stroke(0, 0, 255);
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
      textAlign(CENTER);
      text("wait a minites", width - 100, height - 50);
      textAlign(LEFT);
      if(timelag>=2000) statelag = true;
    }
        /*
        else if (state1 == 5 || state1 == 6 || state1 == 7 || (timefinish - timestart >= 5000 && state1 == 4)) {
        if (e == 1.0&&state1 == 4) { //小指をはじめてたてた時
        n = fx;
        m = fy;
        state1 = 5;
        }
        else if ((e == 0.0&&state1 == 5) || (e == 0.0&&state1 == 6)) {
        noFill();
        strokeWeight(5);
        stroke(0, 255, 0);
        ellipse(n + w2, m + h2, d, d);
        state1 = 6;
        }
        else if (e == 1.0&&state1 == 6) {
        state1 = 7;
        ene_number++;
        Enemy enemy = new Enemy(n + w2, m + h2, d, ene_number); //dは指の間の距離
        enemies.add(enemy);
        }
        else if (e == 0.0&&state1 == 7) {
        state1 = 4;
        timestart = millis();
        }
        stroke(aaa, 255 - aaa, 255);
        strokeWeight(5);
        line(x, y + 16, x, y - 16);    //撃つ方向
        line(x - 16, y, x + 16, y);    //撃つ方向
        }
        */
      }
    }
  else { //positionよくなかったら
    fx = 0;
    fy = 0;
    state1 = 0;
  }
}
