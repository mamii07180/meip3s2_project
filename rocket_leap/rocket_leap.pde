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

int state2 = 0;
int state3 = 0; //OPとゲームを分けるやつ
int state4=0;
int state5=0;
int posi = 0;
int f=0;
float g2=0.0;
int Re=0;
float distanceReplay=0.0;
float timeRestart=0.0;
float timeRefinish=0.0;

Myself myself;
Earth earth;
ArrayList<Enemy> enemies;
ArrayList<Bullet> myBullets;
ArrayList<Bullet> eneBullets; //相手の弾（今回はいらない）
int hp,hit;
float aaa=1;
int aa;
int da=5;
float w2, h2; //画面の半分サイズ（よく使うので）
float d;
float xx, yy;
//boolean state = false;
int ene_number = 0;
int enecount;
int enecountb;

//通信用
Server s;
Client client;
String input;

int[] data = new int[3];
float[] x;
HandList hands;

//エフェクト
ImgList imgList;
StukaEffect stukaEffect;
PImage img; //地球

void setup() {
  //  s = new Server(this, 12345); // Start a simple server on a port
  //  client = new Client(this, "157.82.200.251",12345); //takumi
  //client = new Client(this, "127.0.0.1", 12345); //自分でテストする用
   client = new Client(this, "157.82.202.205", 10000); //mamii

  size(1280, 640);
  //  fullScreen(P3D);
  w2 = width / 2;
  h2 = height / 2;

  myself = new Myself();
  enemies = new ArrayList<Enemy>();
  myBullets = new ArrayList<Bullet>();
  eneBullets = new ArrayList<Bullet>(); 

  imgList = new ImgList();
  stukaEffect = new StukaEffect();
  imageMode(CENTER);
  
  img = loadImage("chikyuu.png");
  client.write(7 + " " + width + " " + height + "\n"); //縦横比
  //opつけるときは消す（作業用）
   // replace();
//    earth = new Earth();
}

void draw() {
  background(0);
  aa = aa + da; //色に使うやつ
  aaa = (int)aa;
  if (aa>255 || aa<0) {
    da = -da;
    aa = aa + da;
  }

  Frame frame = leap.frame();
  hands = frame.hands();
 //  iBox = frame.interactionBox();
  Hand[] hand = new Hand[2];
  Vector[] palmPos = new Vector[2];
  x= new float[6];
  for(int i = 0; i<2; i++)  {
    hand[i]=hands.get(i);
    palmPos[i]=hand[i].palmPosition();
  }
  x = fingergap1(hand[0], hand[1]);
  if (state3 == 0) { //初期状態
    opening();
  }
  else if (state3 == 1) { //opおわった後
    float edist = dist(earth.loc.x, earth.loc.y, myself.loc.x, myself.loc.y);
    if (hp<=0 || edist<=45) { //HPがなくなったor到着したらおわり
      gameover(edist);
      println(hp + edist);
    } else { //--------------------ゲーム
      if (palmPos[0].getX()>palmPos[1].getX() && hands.count() == 2) { //いい感じの場所だったら
        posi = 1;
      }
      else {
        posi = 0;
      }
      textAlign(LEFT);
      drawFingerTip(x[0], x[2], x[3], x[4], posi); //敵生成

      myself.display();
      earth.display();
      for (Enemy enemy : enemies) {
        enemy.display();
      }
      for (Bullet bullet : myBullets) {
        bullet.display();
      }

      myself.update();
      //敵のリスト更新
      ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
      for (Enemy enemy : enemies) {
        enemy.update();
        if(enemy.enebig==1) println(enemy.size);
        if (!enemy.isDead) {
          nextEnemies.add(enemy);
        } else {
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

      //HPと撃墜数の表示
      fill(255);
      textSize(26);
      noStroke();
      noFill();
      stroke(255);
      strokeWeight(1);
      rect(82, 22, 106, 18);
      if (hp<=300)fill(255, 0, 0);
      else fill(0, 255, 0);
      text("HP", 30, 45);
      rectMode(CORNER);
      noStroke();
      rect(85, 25, hp/10, 12);
      fill(255);
      text("HIT", 30, 70);
      text(hit, 80, 70);
      noFill();
      stroke(0, 255, 0);
      rect(width-175, 30, 150, 100); //ロケット座標用
      textSize(30);
      fill(255);
      text("x:", width-160, 65);
      text("y:", width-160, 105);
      
       if (palmPos[0].getX()>palmPos[1].getX() && hands.count() == 2) { //いい感じの場所だったら
      }
      else {
        fill(122 + aaa / 2);
        if (hands.count() == 1) {
          textAlign(CENTER);
          text("Put Both Hands", w2, h2);
        }
        else {
          textAlign(CENTER);
          text("Put Your Hands", w2, h2);
        }
      }
      
      stroke(255);
      noFill();
      strokeWeight(3);
      line(10, 10, 10, 60);    //四つ角
      line(10, 10, 60, 10);    
      line(width-10, height-10, width-10, height-60);    
      line(width-10, height-10, width-60, height-10);    
      line(10, height-10, 10, height-60);    
      line(10, height-10, 60, height-10);    
      line(width-10, 10, width-10, 60);    
      line(width-10, 10, width-60, 10);    

      stukaEffect.effectPlay();
    }  
  }
}
class Myself { //-------------------------ロケット

  int i=0;
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
    if (isDead) {
      fill(255, 255, 0);
      stroke(0, 255, 0);
      i = i++;
    } else {
      fill(255, 0, 0);
      stroke(255, 0, 0);
    }
    ellipse(loc.x, loc.y, size, size);
    noFill();
    stroke(255, 255, 255, 100);
    strokeWeight(15);
    ellipse(loc.x, loc.y, size/2, size/2);
    stroke(255);
    strokeWeight(3);
    ellipse(loc.x, loc.y, size/2, size/2);
  }

  void update() {
    isDead = false;

    // Receive data from client
    //    client = c.available();
    if (client.available() > 0) {
      input = client.readString();
      input = input.substring(0, input.indexOf("\n")); // Only up to the newline
      data = int(split(input, ' ')); // Split values into an array
      // Draw line using received coords
      if (data[0]==0) { //位置情報
        fill(255);
        rocketX = data[1]+w2;
        rocketY = data[2]+h2;
        loc.x=rocketX;
        loc.y=rocketY;
        textSize(20);
        text(rocketX, width-130, 65);
        text(rocketY, width-130, 105);
      } else if (data[0]==1) { //銃発射
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
        hp = hp-100;
        hit = hit + 1;
        client.write(4+" "+e.number+" "+1+"\n"); //死滅かつhp減
        break;
      }
    }
  }
}

class Earth { //-------------------------地球
  PVector loc;
  float size;
  float x,y,angle;
  boolean ok=false;

  Earth() {
    size = 200;
    while(abs(w2-x)<300 || abs(y-h2)<300 || !ok){ //場所をいい感じの所に調整
      x = random(width);
      y = random(height);
      for (Enemy e : enemies){
        if(dist(x, y, e.loc.x, e.loc.y)<=100) {
          ok = false;
          break;
        } else {
          ok = true;
        }
      }
    }
    loc = new PVector(x, y);
    client.write(6+" "+(int)((loc.x-w2)*10) +" "+(int)((loc.y-h2)*10) +"\n"); 
    println(loc.x,loc,y);
    delay(100);
  }

  void display() {
    angle=angle+0.01;
    if(angle >=2*PI) angle = 0;
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
    } else { //敵が撃つ場合
      stroke(255, 0, 0);
    }
    pushMatrix();
    translate(loc.x, loc.y);//円の中心に座標を合わせます
    rotate(bangle);
    line(0, 0, 0, vel);    //撃つ方向
    popMatrix();
  }

  void update() {
    loc.x += -vel*sin(bangle);
    loc.y += vel*cos(bangle);
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
  boolean isDead;
  int number;
  int enebig; //0:普通、b=1:強い敵
  int timebig;

  Enemy(float x, float y, float dis, int ene_number, int b) { //b=0:普通、b=1:強い敵
    size = dis;
    number = ene_number;
    loc = new PVector(x, y);
    isDead = false;
    enebig=b;
    if(enebig ==1) println("big"+ size);
    client.write(2 + " " + number + " " + (int)((loc.x - w2) * 10) + " " + (int)((loc.y - h2) * 10) + " " + (int)size * 10 + " " + enebig + "\n");
    if(enebig==1) timebig = (int)millis();
    println(number,loc.x,+loc.y,size);
    delay(100);
    println(loc.x,loc.y);//個体番号、座標、半径を送信
  }

  void display() {
    if(enebig==1) fill(255);
    else fill(255 - aaa, 255, aaa);
    stroke(255 - aaa, 255, aaa);
    if(enebig == 1){
      float scale = (millis()-timebig)%2000;
      if (scale>1000) {
        scale = 2000-scale;
      }
      println(scale);
      ellipse(loc.x, loc.y, size*(1+scale/1000), size*(1+scale/1000));
    } else {
      ellipse(loc.x, loc.y, size, size);
    }
  }

  void update() {
    for (Bullet b : myBullets) { //あたり判定
      if ((loc.x - size / 2 <= b.loc.x && b.loc.x <= loc.x + size / 2)
        && (loc.y - size / 2 <= b.loc.y && b.loc.y <= loc.y + size / 2)) {
        isDead = true;
        b.isDead = true;
        hit = hit+1;
        stukaEffect.setEffect(Const.IMAGE_EXPLODE, (int)loc.x, (int)loc.y);
        client.write(4+" "+number+" "+0+"\n");  //死滅した個体番号を送信
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
    vertex(r*cos(radians(360*i/3)), r*sin(radians(360*i/3)));
  }
  endShape(CLOSE);

  popMatrix();
}

void mouseReleased() 
{ 
  /*  if(mouseButton==RIGHT){
   d = dist(xx, yy, mouseX, mouseY);
   enemies.add(new Enemy(xx, yy, d));
   state =false;
   }
   if(mouseX<=w2+180&&mouseY<=h2+80&&mouseX>=w2&&mouseY>=h2+20){
   hp = 1000;
   hit = 0;
   background(0);
   for(int i = 0; i < 15; i++){ //最初に敵を15体作っておく
   for(Enemy enemy: enemies){
   enemy.display();
   }
   //敵のリスト更新
   ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
   for(Enemy enemy: enemies){
   enemy.update();
   if(!enemy.isDead){
   nextEnemies.add(enemy);
   }
   }
   enemies = nextEnemies;
   //  if(random(1) < 0.02){ //更新100回に2回の割合で敵作製
   enemies.add(new Enemy(0,0,random(25)*2));
   //  }
   }
   
   }*/
}

float[] fingergap1(Hand hand1,Hand hand2){

  float[] xx=new float[6];
  FingerList [] fingers = new FingerList[2];
  Finger[]  finger = new Finger[4];
  Vector[]  tipPos = new Vector[4];
  fingers[0] = hand1.fingers();
  fingers[1] = hand2.fingers();
  //x[4]=0.0;
  finger[0]=fingers[0].get(2);
  finger[1]=fingers[0].get(1);
  for (int i = 2; i<4; i++)
  {
    finger[i]=fingers[1].get(i-2);
  }
  for (int i=0; i<4; i++)
  {
    tipPos[i]=finger[i].tipPosition();
  }
  xx[0]=tipPos[1].getX();
  xx[1]=tipPos[1].getY();
  xx[2]=tipPos[1].getZ();
  xx[3]=gap(tipPos[2].getX()-tipPos[3].getX(), tipPos[2].getY()-tipPos[3].getY(), tipPos[2].getZ()-tipPos[3].getZ());
  if (finger[0].isExtended()==true)
  {
    xx[4]=1.0;
  } else
  {
    xx[4]=0.0;
  }
  Vector fingertip1 = finger[1].tipPosition();
  if((fingertip1.getY()>400&&state2==0)||(fingertip1.getY()>=200&&state2==1)){
    xx[5]=1.0;
    state2=1;
  }else if((fingertip1.getY()<200&&state2==1)||(fingertip1.getY()<=300&&state2==2)){
    xx[5]=2.0;
    state2=2;
  }else if((fingertip1.getY()>300&&state2==2)||state2==3){
    xx[5]=3.0;
    state2=3;
  }else{
    xx[5]=0.0;
  }
    return xx;
}

float gap(float xx, float y, float z) {
  float a;
  a = sqrt(xx*xx+y*y+z*z);
  return a;
}
