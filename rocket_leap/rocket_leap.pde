import com.leapmotion.leap.*;
import processing.net.*;


/**
* simple 2D shooter game
*
* @author aa_debdeb
* @date 2016/08/30
*/

Controller leap = new Controller();         // leap という名前で Controller オブジェクトを宣言
InteractionBox iBox;                        // InteractionBox オブジェクト（座標変換などをする）を宣言

int state1=0;
int state2=0;
int f=0;
float n,m;
float timestart=0.0;
float timefinish=0.0;

Myself myself;
ArrayList<Enemy> enemies;
ArrayList<Bullet> myBullets;
ArrayList<Bullet> eneBullets; //相手の弾（今回はいらない）
int hp=1000;
int hit=0;
int aaa=1;
int da=1;
int resizeX,resizeY;
float w2,h2; //画面の半分サイズ（よく使うので）
float d;
float xx,yy;
boolean state=false;
int ene_number=0;

//通信用
Server s;
Client client;
String input;
int[] data = new int[3];

void setup(){
  s = new Server(this, 12345); // Start a simple server on a port
  
  size(2560,1280);
//  fullScreen(P3D);
  resizeX = (int)width/500;
  resizeY = (int)height/200;
  w2 = width/2;
  h2 = height/2;

  myself = new Myself();
  enemies = new ArrayList<Enemy>();
  myBullets = new ArrayList<Bullet>();
  eneBullets = new ArrayList<Bullet>(); 
  for(int i = 0; i < 15; i++){ //最初に敵を15体作っておく
    ene_number = ene_number+1;
    enemies.add(new Enemy(0,0,random(25)*2,ene_number)); //0,0なら適当に半径生成される(classに記載)
  }
  //敵のリスト更新
    ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
    for(Enemy enemy: enemies){
      enemy.update();
//      if(!enemy.isDead){ //初回は死滅しないのでいらない
        nextEnemies.add(enemy);
//      }
    }
    enemies = nextEnemies;
    for(Enemy enemy: enemies){
      enemy.display();
    }
}

void draw(){
  if(hp<=0) { //HPがなくなったら止まる
    noStroke();
    textSize(86);
    fill(255);
    text("GAME OVER !!", w2, h2);
    if(w2<=mouseX && mouseX<=w2+180 && h2+20<=mouseY && mouseY<=h2+80) {
      fill(255,0,0);
    } else {
 
      fill(255);
    }
    rect(w2+90, h2+50, 180, 60);
    textSize(50);
    fill(0);
    text("REPLAY", w2, h2+70);
    if( mousePressed == true && mouseX<=w2+180
    &&mouseY<=h2+80&&mouseX>=w2&&mouseY>=h2+20){
      hp = 1000;
      hit = 0;
//      s.write(2+" "+hit + "\n");
      s.write(3+ "\n"); //向こうにリセットを知らせる
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
  //    if(random(1) < 0.02){ //更新100回に2回の割合で敵作製
        ene_number++;
        enemies.add(new Enemy(0,0,random(25)*2,ene_number));
  //    }
      }
    }
  } else { //--------------------ゲーム
     // Frame frame = leap.frame();               // Frame オブジェクトを宣言し、leap のフレームを入れる
      //HandList hands = frame.hands();           // HandList オブジェクトを宣言し、frame 内の手（複数）の情報を取得
//      iBox = frame.interactionBox();            // InteractionBox を初期化

    background(0);
    stroke(255);
    noFill();
    rect(5, 5, width-5, height-5); 
    myself.display();
    for(Enemy enemy: enemies){
      enemy.display();
    }
    for(Bullet bullet: myBullets){
      bullet.display();
    }
/*  for(Bullet bullet: eneBullets){
    bullet.display();
  }*/

  myself.update();
  //敵のリスト更新
  ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
  for(Enemy enemy: enemies){
    enemy.update();
    if(!enemy.isDead){
      nextEnemies.add(enemy);
    } else {
//      s.write(4+" "+ene_number +"\n"); //死亡した個体番号を知らせる
    }
  }
  enemies = nextEnemies;
  ene_number++;
  //銃リスト更新
  ArrayList<Bullet> nextMyBullets = new ArrayList<Bullet>();
  for(Bullet bullet: myBullets){
    bullet.update();
    if(!bullet.isDead){
      nextMyBullets.add(bullet);
    }
  }
  myBullets = nextMyBullets;
/* //敵の銃リスト更新 
  ArrayList<Bullet> nextEneBullets = new ArrayList<Bullet>();
  for(Bullet bullet: eneBullets){
    bullet.update();
    if(!bullet.isDead){
      nextEneBullets.add(bullet);
    }
  }
  eneBullets = nextEneBullets;*/
/*  if(mousePressed && mouseButton==RIGHT && state == false &&
  dist(myself.loc.x, myself.loc.y, mouseX, mouseY)>=100) {
    xx = mouseX;
    yy = mouseY;
    state = true;*/
//    enemies.add(new Enemy(mouseX, mouseY, d)); //右クリックで敵追加
  }
  
  
  //カーソルの表示
  
  //HPと撃墜数の表示
  fill(255);
  textSize(26);
  noFill();
  stroke(255);
  strokeWeight(1);
  rect(62, 12,106, 18);
  fill(0,255,0);
  text("HP", 10, 35);
//  text(hp, 60, 35);
  rectMode(CORNER);
  noStroke();
  rect(65, 15, hp/10, 12);
  fill(255);
  text("HIT", 10, 60);
  text(hit, 60, 60);
  
  Frame frame = leap.frame();
  HandList hands = frame.hands();
//  iBox = frame.interactionBox();
  Hand[] hand = new Hand[2];
  Vector[] palmPos = new Vector[2];
  float[] x= new float[5];
  for(int i = 0; i<2; i++)  {
    hand[i]=hands.get(i);
    palmPos[i]=hand[i].palmPosition();
  }
  if(palmPos[0].getX()>palmPos[1].getX()&&hands.count()==2){
  f=1;
  }
  else{
  f=0;
  }
  x = fingergap1(hand[0],hand[1]);
  if(x[5]==0.0){
    textSize(80);
    fill(255);
    text("この世は無である..",600,600);
  }else if(x[5]==1.0){
    textSize(80);
    fill(255);
    text("光..",600,600);
  }else if(x[5]==2.0){
  drawFingerTip(x[0],x[2],x[3],x[4],f);
  }
  
}

void drawFingerTip(float a,float b,float d,float e,int f) {
  float fx,fy, x, y; //指の位置
  fx = resizeX*a;
  fy = resizeY*b;
  x=fx+ w2; //左上が原点
  y=fy+ h2;
  if(f==1){
    if(fx<= -w2|| fx>= w2 || fy<= -h2 || fy>= h2 ){
      if(fx<= -w2) x=0;
      if(fx>= w2) x=width;
      if(fy<= -h2) y=0;
      if(fy>= h2) y=height;  
      stroke(255);
      drawTriangle(x, y, 50);  // 横の位置、縦の位置、円の半径
    }else {
        float dis = dist(myself.loc.x, myself.loc.y, x, y);
        if ( dis<=100 ){ //ロケットとカーソルの位置が近すぎたら
        noFill();
        strokeWeight(5);
        stroke(255, 0, 0);
        ellipse(myself.loc.x, myself.loc.y, 2*dis, 2*dis);
        }else {
         timefinish = millis();
         if(state1==0||(state1==4&&timefinish-timestart>2000)||state1==1||state1==2||state1==3){
           if((e==1.0&&state1==0)||(e==1.0&&state1==4)){ //小指をはじめてたてた時
              n=fx;
              m=fy;
              state1=1;
           }else if((e==0.0&&state1==1)||(e==0.0&&state1==2)){
              noFill();
              strokeWeight(5);
              stroke(0,255,0);
              ellipse(n+w2,m+h2,d,d);
              state1=2;
           }else if(e==1.0&&state1==2){
              state1=3;
              Enemy enemy =new Enemy(n+w2, m+h2, d, ene_number); //dは指の間の距離
              enemies.add(enemy);
           }else if(e==0.0&&state1==3){
              state1=4;
              timestart = millis();
           }
              stroke(255-aaa,255,aaa);
              strokeWeight(5);
              line(x, y+16, x, y-16);    //撃つ方向
              line(x-16, y, x+16, y);    //撃つ方向
         }else{
              stroke(0,0,255);
              strokeWeight(5);
              line(x, y+16, x, y-16);    //撃つ方向
              line(x-16, y, x+16, y);    //撃つ方向
         }
        }
    }
   }else{
    fx=0;
    fy=0;
    state1=0;
    textSize(80);
    fill(255);
    text("NO SIGNAL",600,600);
  }
/*
  fill(0,255,0);
  textSize(56);
  text(fx, 0, height-100); //-250~250がよさそう
  textSize(56);
  text(fy, 0, height-50); //-250~250がよさそう
  */
}

class Myself{ //-------------------------ロケット
  
  int i=0;
  PVector loc;
  float size;
  float dmx,dmy,angle,rocketX,rocketY;
  int coolingTime;
  boolean isDead;
  
  Myself(){ 
    size = 40;
    loc = new PVector(w2, height - size / 2 - 10);
    coolingTime = 0;
    isDead = false;
  }
  
  void display(){
    if(isDead || i%6!=0){
      fill(255, 255, 0);
      stroke(0, 255, 0);
      i = i++;
    } else {
      fill(255,0,0);
      stroke(255,0, 0);
    }
    ellipse(loc.x, loc.y, size, size);
    fill(0,255,0);
    ellipse(loc.x, loc.y, size/2, size/2);
//    pushMatrix();
//    translate(loc.x, loc.y);//円の中心に座標を合わせます
//    rotate(angle);
//    drawTriangle(0, 0, size);  // 横の位置、縦の位置、円の半径
//    fill(0,255,0);
//    drawTriangle(0, -size/2, size/2);  // てっぺんを青く
//    popMatrix();
  }
  
  void update(){
    isDead = false;
    
    // Receive data from client
    client = s.available();
    if (client != null) {
      input = client.readString();
      input = input.substring(0, input.indexOf("\n")); // Only up to the newline
      data = int(split(input, ' ')); // Split values into an array
      // Draw line using received coords
      if(data[0]==0){
        stroke(0);
        rocketX = data[1];
        rocketY = data[2];
        loc.x=rocketX;
        loc.y=rocketY;
      }else if(data[0]==1){
        angle = -data[1]*PI/2;
        if( coolingTime >= 10){
          myBullets.add(new Bullet());
          coolingTime = 0;
        }
      }
    }

//    float dmx = rocketX - loc.x;
//    float dmy = rocketY - loc.y;
//    if(dmx != 0 && dmy !=0){
//      angle = angle+constrain(atan2(dmx,-dmy)-angle, -PI/12, PI/12);
//    }
//    dmx = constrain(dmx, -3, 3); //最小値-5最大値5
   // loc.x += dmx;
//    dmy = constrain(dmy, -3, 3); //最小値-5最大値5
   // loc.y += dmy; 
    coolingTime++;
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
    for(Enemy e: enemies){
      if(abs(loc.x - e.loc.x) < size / 2 + e.size / 2 && abs(loc.y - e.loc.y) < size / 2 + e.size / 2){
        isDead = true;
        i = i++;
        e.isDead = true;
        hp = hp-100;
        s.write(4+" "+e.number+" "+1+"\n");
        break;
      }
    }
  }
}

class Bullet{ //-------------------------銃
  
  PVector loc;
  float vel;
  float bangle=myself.angle;
  boolean isMine;
  boolean isDead;
  
  Bullet(){ //自分の銃
    loc = new PVector(myself.loc.x, myself.loc.y);
    vel = -10; //移動速度
    isMine = true;
  }
  
  Bullet(Enemy enemy){ //敵の銃
    loc = new PVector(enemy.loc.x, enemy.loc.y);
    vel = 5; 
    isMine = false;
  }
  
  void display(){
    strokeWeight(3);
    if(isMine){ //自分がうつばあい
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

  void update(){
    loc.x += -vel*sin(bangle);
    loc.y += vel*cos(bangle);
    if((vel > 0 && loc.y > height) || (vel < 0 && loc.y < 0)){
      isDead = true;
    }
  }  
}

class Enemy{ //-------------------------------敵
  
  PVector loc;
  PVector syoki_loc;
//  float vel;
  float size;
  int coolingTime;
  boolean isDead;
  int number;
  
  Enemy(float x, float y, float dis, int ene_number){
    size = dis;
    number = ene_number;
//  Enemy(){
//    size = random(25)*2;
    if (x==0&&y==0){
      loc = new PVector(random(width), random(height));
    } else {
      loc = new PVector(x,y);
    }
//    vel = 3;
    coolingTime = int(random(60));
    isDead = false;
    s.write(2+" "+number+" "+(int)loc.x+"\n");  //個体番号、座標、半径を送信
    s.write(5+" "+(int)loc.y+" "+size+"\n");  //個体番号、座標、半径を送信
  }
  
  void display(){
//    fill(206,117,48);
    aaa=aaa+da;
    if(aaa>255) {
      aaa=255;
      da = -1;
    }
    if(aaa<0) {
      aaa=0;
      da = 1;
    }
    fill(255-aaa,255,aaa);
    stroke(255-aaa,255,aaa);
    ellipse(loc.x, loc.y, size, size);
    //rect(loc.x, loc.y, size, size);
  }

  void update(){
//    loc.y = vel;
    if(loc.y > height){
      isDead = true;
    }
//    coolingTime++;
//    if(coolingTime >= 60){
//      eneBullets.add(new Bullet(this));
//      coolingTime = 0;
//    }
    for(Bullet b: myBullets){ //あたり判定
      if((loc.x - size / 2 <= b.loc.x && b.loc.x <= loc.x + size / 2)
         && (loc.y - size / 2 <= b.loc.y && b.loc.y <= loc.y + size / 2)){
        isDead = true;
        b.isDead = true;
        hit = hit+1;
        s.write(4+" "+number+" "+0+"\n");  //死滅した個体番号を送信
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
  float[] x=new float[6];
  FingerList [] fingers = new FingerList[2];
  Finger[]  finger = new Finger[4];
  Vector[]  tipPos = new Vector[4];
  fingers[0] = hand1.fingers();
  fingers[1] = hand2.fingers();
  //x[4]=0.0;
  finger[0]=fingers[0].get(2);
  finger[1]=fingers[0].get(1);
  for(int i = 2; i<4;i++)
  {
    finger[i]=fingers[1].get(i-2);
  }
  for(int i=0;i<4;i++)
  {
    tipPos[i]=finger[i].tipPosition();
  }
  x[0]=tipPos[1].getX();
  x[1]=tipPos[1].getY();
  x[2]=tipPos[1].getZ();
  x[3]=gap(tipPos[2].getX()-tipPos[3].getX(),tipPos[2].getY()-tipPos[3].getY(),tipPos[2].getZ()-tipPos[3].getZ());
  if(finger[0].isExtended()==true)
  {
    x[4]=1.0;
  }
  else
  {
    x[4]=0.0;
  }
  Vector fingertip1 = finger[1].tipPosition();
  if(fingertip1.getY()>400&&state2==0){
    state2=1;
    x[5]=1.0;
  }else if(fingertip1.getY()<200&&state2==1){
    state2=2;
    x[5]=2.0;
  }
    x[5]=0.0;
    textSize(80);
    fill(255);
    text(fingertip1.getY(),600,600);
    return x;
}

float gap(float x,float y,float z){
  float a;
  a = sqrt(x*x+y*y+z*z);
  return a;
}
