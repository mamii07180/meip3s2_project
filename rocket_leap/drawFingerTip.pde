void drawFingerTip(float a, float b, float d, float e, int posi) {
  int state1 = 4;
  float fx, fy, x, y; //指の位置
  float n, m;
  float timestart = -2000;
  float timelag=2000;
  fx = width / 250 * a;
  fy = height / 100 * b;
  x = fx + w2 - 100; //左上が原点、右にちょいずれ
  y = fy + h2;
  n = x;
  m = y;
  if (posi == 1) { //手の位置がいい感じだったら
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
    }
    else {
      float dis = dist(myself.loc.x, myself.loc.y, x, y); //ロケットとの距離
      float edis = dist(earth.loc.x, earth.loc.y, x, y); //地球との距離
      if (dis <= 100) { //ロケットとカーソルの位置が近すぎたら
        noFill();
        strokeWeight(5);
        stroke(255, 0, 0);
        ellipse(myself.loc.x, myself.loc.y, 2 * dis, 2 * dis);
      }
      else if (edis <= 100) { //ロケットとカーソルの位置が近すぎたら
        noFill();
        strokeWeight(5);
        stroke(255, 0, 0);
        ellipse(earth.loc.x, earth.loc.y, 2 * edis, 2 * edis);
      }
      else {
        if ((state1 == 4 && millis() - timestart>2000) || state1 <= 3) {
          if (e == 1.0&&state1 == 4) { //0:初期、4:それ以降→指のばす
            timelag = millis() - timestart; //今の時間
            n = x; //中心点
            m = y; //中心点
            state1 = 1;
          }
          else if ((e == 0.0&&state1 == 1) || (e == 0.0&&state1 == 2)) { //ゆびまげて、半径調節
            noFill();
            strokeWeight(5);
            stroke(0, 255, 0);
            ellipse(n, m, d, d);
            state1 = 2;
          }
          else if (e == 1.0&&state1 == 2) { //指もっかいのばす
            if (timelag >= 5000) {
              ene_number++;
              enemies.add(new Enemy(n, m, d, ene_number, 1)); //dは指の間の距離、
              int dead_ene_num = ene_number - 15;
              Enemy dead = enemies.get(dead_ene_num);
              if (!dead.isDead) {
                dead.isDead = true;
                enemies.set(dead_ene_num, dead);
                client.write(4 + " " + dead_ene_num + " " + 0 + "\n"); //死滅個体
              }
            }
            else {
              ene_number++;
              enemies.add(new Enemy(n, m, d, ene_number, 0)); //dは指の間の距離、
              int dead_ene_num = ene_number - 15;
              Enemy dead = enemies.get(dead_ene_num);
              if (!dead.isDead) {
                dead.isDead = true;
                enemies.set(dead_ene_num, dead);
                client.write(4 + " " + dead_ene_num + " " + 0 + "\n"); //死滅個体
              }
            }
            state1 = 3;
          }
          else if (e == 0.0&&state1 == 3) {
            state1 = 4;
            timestart = millis(); //星を作った時間
          }
          stroke(255 - aaa, 255, aaa);
          strokeWeight(5);
          line(x, y + 16, x, y - 16);    //撃つ方向
          line(x - 16, y, x + 16, y);    //撃つ方向
        }
        else if (millis() - timestart <= 2000) {
          stroke(0, 0, 255);
          strokeWeight(5);
          line(x, y + 16, x, y - 16);    //撃つ方向
          line(x - 16, y, x + 16, y);    //撃つ方向
          text("wait a minites", width - 100, height - 50);
        }
        /*        else if (state1 == 5 || state1 == 6 || state1 == 7 || (timefinish - timestart >= 5000 && state1 == 4)) {
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
        }*/
      }
    }
  }
  else { //positionよくなかったら
       //    fx = 0;
       //    fy = 0;
    state1 = 4;
  }
}
