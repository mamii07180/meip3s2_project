import com.leapmotion.leap.*;
import processing.net.*;


/**
* simple 2D shooter game
*
* @author aa_debdeb
* @date 2016/08/30
*/

Controller leap = new Controller();         // leap という名前で Controller オブジェクトを宣言
                      //InteractionBox iBox;                        // InteractionBox オブジェクト（座標変換などをする）を宣言

int state3 = 0;
int f = 0;
int g1 = 0;

Myself myself;
Earth earth;
ArrayList<Enemy> enemies;
ArrayList<Bullet> myBullets;
ArrayList<Bullet> eneBullets; //相手の弾（今回はいらない）
int hp = 1000;
int hit = 0;
float aa = 1;
int aaa = 1;
float da = 3;
float w2, h2; //画面の半分サイズ（よく使うので）
float d;
float xx, yy;
boolean state = false;
int ene_number = 0;

//通信用
Server s;
Client client;
String input;

int[] data = new int[3];

//エフェクト
ImgList imgList;
StukaEffect stukaEffect;
PImage img; //地球

void setup() {
  //  s = new Server(this, 12345); // Start a simple server on a port
  //  client = new Client(this, "157.82.200.251",12345); // Start a simple server on a port
  client = new Client(this, "127.0.0.1", 12345); //自分でテストする用
                           // client = new Client(this, "157.82.202.205", 10000); //mamii

  size(1280, 640);
  //  fullScreen(P3D);
  w2 = width / 2;
  h2 = height / 2;

  myself = new Myself();
  enemies = new ArrayList<Enemy>();
  myBullets = new ArrayList<Bullet>();
  eneBullets = new ArrayList<Bullet>();
  for (int i = 0; i < 15; i++) { //最初に敵を15体作っておく
    ene_number++;
    float ene_x, ene_y, ene_r;
    while (true) {
      ene_x = random(width);
      ene_y = random(height);
      ene_r = (15 + random(30)) * 2;
      if (abs(w2 - ene_x) > 40 + ene_r && abs(height - 30 - ene_y) > 40 + ene_r) break;
    }
    enemies.add(new Enemy(ene_x, ene_y, ene_r, ene_number, 0)); //0,0なら適当に半径生成される(classに記載)
  }
  //敵のリスト更新
  ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
  for (Enemy enemy : enemies) {
    enemy.update();
    //      if(!enemy.isDead){ //初回は死滅しないのでいらない
    nextEnemies.add(enemy);
    //      }
  }
  enemies = nextEnemies;

  earth = new Earth();

  imgList = new ImgList();
  stukaEffect = new StukaEffect();
  imageMode(CENTER);

  img = loadImage("chikyuu.png");
}

void draw() {
  aa = aa + da;
  aaa = (int)aa;
  if (aa>255) {
    aa = 255;
    da = -da;
  }
  if (aa<0) {
    aa = 0;
    da = -da;
  }

  float edist = dist(earth.loc.x, earth.loc.y, myself.loc.x, myself.loc.y);
  if (hp <= 0 || edist <= 45) { //HPがなくなったor到着したらおわり
    client.write(6 + "\n");
    background(0);
    noStroke();
    textSize(86);
    fill(255);
    if (hp <= 0) text("YOU WIN!!", w2, h2);
    else text("YOU LOSE...", w2, h2);
    if (w2 <= mouseX && mouseX <= w2 + 180 && h2 + 20 <= mouseY && mouseY <= h2 + 80) {
      fill(255, 0, 0);
    }
    else {
      fill(255);
    }
    rect(w2, h2 + 20, 180, 60);
    textSize(50);
    fill(0);
    text("REPLAY", w2, h2 + 70);
    if (mousePressed == true && mouseX <= w2 + 180 && mouseY <= h2 + 80 && mouseX >= w2 && mouseY >= h2 + 20) {
      hp = 1000;
      hit = 0;
      //      client.write(2+" "+hit + "\n");
      client.write(3 + "\n"); //向こうにリセットを知らせる
      background(0);
      for (int i = 0; i < 15; i++) { //最初に敵を15体作っておく
        for (Enemy enemy : enemies) {
          enemy.display();
        }
        //敵のリスト更新
        ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
        for (Enemy enemy : enemies) {
          enemy.update();
          if (!enemy.isDead) {
            nextEnemies.add(enemy);
          }
        }
        enemies = nextEnemies;
        //    if(random(1) < 0.02){ //更新100回に2回の割合で敵作製
        ene_number = ene_number + 1;
        enemies.add(new Enemy(0, 0, (15 + random(10)) * 2, ene_number, 0));
        //    }
      }
    }
  }
  else { //--------------------ゲーム
       // Frame frame = leap.frame();               // Frame オブジェクトを宣言し、leap のフレームを入れる
       //HandList hands = frame.hands();           // HandList オブジェクトを宣言し、frame 内の手（複数）の情報を取得
       //      iBox = frame.interactionBox();            // InteractionBox を初期化

    background(0);
    stroke(255);
    noFill();
    //    rect(5, 5, width-5, height-5); 
    strokeWeight(3);
    line(10, 10, 10, 60);    //四つ角
    line(10, 10, 60, 10);
    line(width - 10, height - 10, width - 10, height - 60);
    line(width - 10, height - 10, width - 60, height - 10);
    line(10, height - 10, 10, height - 60);
    line(10, height - 10, 60, height - 10);
    line(width - 10, 10, width - 10, 60);
    line(width - 10, 10, width - 60, 10);

    myself.display();
    earth.display();
    for (Enemy enemy : enemies) {
      enemy.display();
    }
    for (Bullet bullet : myBullets) {
      bullet.display();
    }
    /*  for(Bullet bullet: eneBullets){
    bullet.display();
    }*/

    myself.update();
    //敵のリスト更新
    ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
    for (Enemy enemy : enemies) {
      enemy.update();
      if (!enemy.isDead) {
        nextEnemies.add(enemy);
      }
      else {
        //        client.write(4+" "+ene_number +"\n"); //死亡した個体番号を知らせる
      }
    }
    enemies = nextEnemies;
    //銃リスト更新
    ArrayList<Bullet> nextMyBullets = new ArrayList<Bullet>();
    for (Bullet bullet : myBullets) {
      bullet.update();
      if (!bullet.isDead) {
        nextMyBullets.add(bullet);
      }
    }
    myBullets = nextMyBullets;
    /*
    //敵の銃リスト更新
    ArrayList<Bullet> nextEneBullets = new ArrayList<Bullet>();
    for(Bullet bullet: eneBullets){
    bullet.update();
    if(!bullet.isDead){
    nextEneBullets.add(bullet);
    }
    }
    eneBullets = nextEneBullets;
    */
    /*
    if(mousePressed && mouseButton==RIGHT && state == false && dist(myself.loc.x, myself.loc.y, mouseX, mouseY)>=100) {
    xx = mouseX;
    yy = mouseY;
    state = true;
    enemies.add(new Enemy(mouseX, mouseY, d)); //右クリックで敵追加
    }
    */

    //HPと撃墜数の表示
    fill(255);
    textSize(26);
    noStroke();
    noFill();
    stroke(255);
    strokeWeight(1);
    rect(82, 22, 106, 18);
    if (hp <= 300)fill(255, 0, 0);
    else fill(0, 255, 0);
    text("HP", 30, 45);
    //  text(hp, 60, 35);
    rectMode(CORNER);
    noStroke();
    rect(85, 25, hp / 10, 12);
    fill(255);
    text("HIT", 30, 70);
    text(hit, 80, 70);
    noFill();
    stroke(0, 255, 0);
    rect(width - 175, 30, 150, 100); //ロケット座標用
    textSize(30);
    fill(255);
    text("x:", width - 160, 65);
    text("y:", width - 160, 105);

    stukaEffect.effectPlay();
  }
  Frame frame = leap.frame();
  HandList hands = frame.hands();
  //  iBox = frame.interactionBox();
  Hand[] hand = new Hand[2];
  Vector[] palmPos = new Vector[2];
  float[] x = new float[6];
  for (int i = 0; i<2; i++) {
    hand[i] = hands.get(i);
    palmPos[i] = hand[i].palmPosition();
  }
  if (palmPos[0].getX()>palmPos[1].getX() && hands.count() == 2) {
    f = 1;
  }
  else {
    f = 0;
    fill(122 + aaa / 2);
    if (hands.count() == 1) {
      textAlign(CENTER);
      text("Put Both Hands", w2, h2);
    }
    else {
      textAlign(CENTER);
      text("Put Your Hands", w2, h2);
    }
    textAlign(LEFT);
  }
  x = fingergap1(hand[0], hand[1]);
  if (state3 == 0) {
    if (x[5] == 0.0) {
      background(0);
      textSize(50);
      fill(255, 255, 0, 100 + aaa / 2);
      text("Put Your Hands", w2, h2);
      textSize(80);
      fill(255);
      text("The World is Nothing", 600, 600);
    }
    else if (x[5] == 1.0) {
      background(0);
      textSize(80);
      fill(255);
      text("Let there be...", 600, 600);
    }
    else if (x[5] == 2.0) {
      if (g1<256) {
        background(g1);
        textSize(80);
        fill(255);
        textAlign(CENTER);
        text("Light!!", 600, 600);
        textAlign(LEFT);
        g1++;
      }
      else if (g1 >= 256 && g1<511) {
        background(0,0,0,511 - g1);
        g1++;
      }
      else if (g1 == 511) {
        state3 = 1;
      }
    }
  }
  else if (state3 == 1) {
    drawFingerTip(x[0], x[2], x[3], x[4], f);
  }
}

class Myself { //-------------------------ロケット

  int i = 0;
  PVector loc;
  float size;
  float dmx, dmy, angle, rocketX, rocketY;
  int coolingTime;
  boolean isDead;

  Myself() {
    size = 40;
    loc = new PVector(w2, height - size / 2 - 10);
    coolingTime = 0;
    isDead = false;
  }

  void display() {
    if (isDead || i % 6 != 0) {
      fill(255, 255, 0);
      stroke(0, 255, 0);
      i = i++;
    }
    else {
      fill(255, 0, 0);
      stroke(255, 0, 0);
    }
    ellipse(loc.x, loc.y, size, size);
    noFill();
    stroke(255, 255, 255, 100);
    strokeWeight(15);
    ellipse(loc.x, loc.y, size / 2, size / 2);
    stroke(255);
    strokeWeight(3);
    ellipse(loc.x, loc.y, size / 2, size / 2);
    //    pushMatrix();
    //    translate(loc.x, loc.y);//円の中心に座標を合わせます
    //    rotate(angle);
    //    drawTriangle(0, 0, size);  // 横の位置、縦の位置、円の半径
    //    fill(0,255,0);
    //    drawTriangle(0, -size/2, size/2);  // てっぺんを青く
    //    popMatrix();
  }

  void update() {
    isDead = false;

    // Receive data from client
    //    client = c.available();
    if (client.available() > 0) {
      println("OK");
      input = client.readString();
      input = input.substring(0, input.indexOf("\n")); // Only up to the newline
      data = int(split(input, ' ')); // Split values into an array
                       // Draw line using received coords
      if (data[0] == 0) { //位置情報
        fill(255);
        rocketX = data[1] + w2;
        rocketY = data[2] + h2;
        loc.x = rocketX;
        loc.y = rocketY;
        textSize(20);
        text(rocketX, width - 130, 65);
        text(rocketY, width - 130, 105);
      }
      else if (data[0] == 1) { //銃発射
        float bangle = radians(data[1]);
        myBullets.add(new Bullet(bangle));
      }
    }

    /*
    if(mousePressed && mouseButton==LEFT && coolingTime >= 10){
    myBullets.add(new Bullet());
    coolingTime = 0;
    }
    */
    /*
    for(Bullet b: eneBullets){ //敵からの攻撃（使わない）
    if((loc.x - size / 2 <= b.loc.x && b.loc.x <= loc.x + size / 2)
    && (loc.y - size / 2 <= b.loc.y && b.loc.y <= loc.y + size / 2)){
    isDead = true;
    i = i++;
    b.isDead = true;
    break;
    }
    }
    */
    for (Enemy e : enemies) {
      if (abs(loc.x - e.loc.x) < size / 2 + e.size / 2 && abs(loc.y - e.loc.y) < size / 2 + e.size / 2) {
        isDead = true;
        stukaEffect.setEffect(Const.IMAGE_EXPLODE, (int)e.loc.x, (int)e.loc.y);
        i = i++;
        e.isDead = true;
        hp = hp - 100;
        hit = hit + 1;
        client.write(4 + " " + e.number + " " + 1 + "\n"); //死滅かつhp減
        break;
      }
    }
  }
}

class Earth { //-------------------------地球
  PVector loc;
  float size;
  float x, y, angle;
  boolean ok = false;

  Earth() {
    size = 200;
    while (abs(w2 - x)<300 || abs(y - h2)<300 || !ok) { //場所をいい感じの所に調整
      x = random(width);
      y = random(height);
      for (Enemy e : enemies) {
        if (dist(x, y, e.loc.x, e.loc.y) <= 100) {
          ok = false;
          break;
        }
        else {
          ok = true;
        }
      }
    }
    loc = new PVector(x, y);
    client.write(5 + " " + (int)((loc.x - w2) * 10) + " " + (int)((loc.y - h2) * 10 + 100) + "\n");
    delay(100);
  }

  void display() {
    angle = angle + 0.1;
    if (angle >= 2 * PI) angle = 0;
    pushMatrix();
    translate(loc.x, loc.y);//円の中心に座標を合わせます
    rotate(angle);
    image(img, 0, 0, 80, 80);
    popMatrix();
  }
}


class Bullet { //-------------------------銃
  PVector loc;
  float vel;
  float bangle;
  boolean isMine;
  boolean isDead;

  Bullet(float angle) { //自分の銃
    loc = new PVector(myself.loc.x, myself.loc.y);
    vel = -10; //移動速度
    isMine = true;
    bangle = angle;
  }

  Bullet(Enemy enemy) { //敵の銃
    loc = new PVector(enemy.loc.x, enemy.loc.y);
    vel = 5;
    isMine = false;
  }

  void display() {
    strokeWeight(3);
    if (isMine) { //自分がうつばあい
      stroke(0, 255, 255);
    }
    else { //敵が撃つ場合
      stroke(255, 0, 0);
    }
    pushMatrix();
    translate(loc.x, loc.y);//円の中心に座標を合わせます
    rotate(bangle);
    line(0, 0, 0, vel);    //撃つ方向
    popMatrix();
  }

  void update() {
    loc.x += -vel * sin(bangle);
    loc.y += vel * cos(bangle);
    if ((vel > 0 && loc.y > height) || (vel < 0 && loc.y < 0)) {
      isDead = true;
    }
  }
}

class Enemy { //-------------------------------敵

  PVector loc;
  PVector syoki_loc;
  //  float vel;
  float size;
  int coolingTime;
  boolean isDead;
  int number;

  Enemy(float x, float y, float dis, int ene_number, int big) { //big=0:普通、big=1:強い敵
    if(big == 0){
      size = dis;
    }
    else {
      size = dis + aaa/10;
    }
    number = ene_number;
    loc = new PVector(x, y);
    isDead = false;
    client.write(2 + " " + number + " " + (int)((loc.x - w2) * 10) + " " + (int)((loc.y - h2) * 10 + 100) + " " + (int)size * 10 + "\n");
    delay(100);
    println(loc.x, loc.y);//個体番号、座標、半径を送信
  }

  void display() {
    fill(255 - aaa, 255, aaa);
    stroke(255 - aaa, 255, aaa);
    ellipse(loc.x, loc.y, size, size);
  }

  void update() {
    for (Bullet b : myBullets) { //あたり判定
      if ((loc.x - size / 2 <= b.loc.x && b.loc.x <= loc.x + size / 2)
        && (loc.y - size / 2 <= b.loc.y && b.loc.y <= loc.y + size / 2)) {
        isDead = true;
        b.isDead = true;
        hit = hit + 1;
        stukaEffect.setEffect(Const.IMAGE_EXPLODE, (int)loc.x, (int)loc.y);
        client.write(4 + " " + number + " " + 0 + "\n");  //死滅した個体番号を送信
        break;
      }
    }
  }
}

void drawTriangle(float x, float y, float r) { //三角形の描画
  pushMatrix();
  translate(x, y);  // 中心となる座標
  rotate(radians(-90));

  // 円を均等に3分割する点を結び、三角形をつくる
  beginShape();
  for (int i = 0; i < 3; i++) {
    vertex(r*cos(radians(360 * i / 3)), r*sin(radians(360 * i / 3)));
  }
  endShape(CLOSE);

  popMatrix();
}

void mouseReleased()
{
}

float[] fingergap1(Hand hand1, Hand hand2) {
  int state2 = 0;
  float[] x = new float[6];
  FingerList[] fingers = new FingerList[2];
  Finger[]  finger = new Finger[4];
  Vector[]  tipPos = new Vector[4];
  fingers[0] = hand1.fingers();
  fingers[1] = hand2.fingers();
  //x[4]=0.0;
  finger[0] = fingers[0].get(2);
  finger[1] = fingers[0].get(1);
  for (int i = 2; i<4; i++)
  {
    finger[i] = fingers[1].get(i - 2);
  }
  for (int i = 0; i<4; i++)
  {
    tipPos[i] = finger[i].tipPosition();
  }
  x[0] = tipPos[1].getX();
  x[1] = tipPos[1].getY();
  x[2] = tipPos[1].getZ();
  x[3] = dist(tipPos[2].getX(), tipPos[2].getY(), tipPos[2].getZ(), tipPos[3].getX(), tipPos[3].getY(), tipPos[3].getZ());
  if (finger[0].isExtended() == true)   x[4] = 1.0;
  else                  x[4] = 0.0;
  Vector fingertip1 = finger[1].tipPosition();
  if ((fingertip1.getY()>400 && state2 == 0) || (fingertip1.getY() >= 200 && state2 == 1)) {
    x[5] = 1.0;
    state2 = 1;
  }
  else if ((fingertip1.getY()<200 && state2 == 1) || (fingertip1.getY() <= 300 && state2 == 2)) {
    x[5] = 2.0;
    state2 = 2;
  }
  else if ((fingertip1.getY()>300 && state2 == 2) || state2 == 3) {
    x[5] = 3.0;
    state2 = 3;
  }
  else {
    x[5] = 0;
  }
  return x;
}
/*
float gap(float x, float y, float z) {
  float a;
  a = sqrt(x*x + y*y + z*z);
}*/
