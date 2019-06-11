import com.leapmotion.leap.*;

/**
* simple 2D shooter game
*
* @author aa_debdeb
* @date 2016/08/30
*/
Controller leap = new Controller();         // leap という名前で Controller オブジェクトを宣言
//InteractionBox iBox;                        // InteractionBox オブジェクト（座標変換などをする）を宣言


Myself myself;
ArrayList<Enemy> enemies;
ArrayList<Bullet> myBullets;
ArrayList<Bullet> eneBullets; //相手の弾（今回はいらない）
int hp=1000;
int hit=0;
int a=1;
int da=1;
int resizeX,resizeY;
float w2,h2;
float d;
float xx,yy;
boolean state=false;
void setup(){
//  size(1280, 1280);
  fullScreen(P3D);
  resizeX = (int)width/500;
  resizeY = (int)height/200;
  w2 = width/2;
  h2 = height/2;
//  int resizeX = weight/500;
  rectMode(CENTER);
  myself = new Myself();
  enemies = new ArrayList<Enemy>();
  myBullets = new ArrayList<Bullet>();
  eneBullets = new ArrayList<Bullet>(); 
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
}

void draw(){
  if(hp<=0) { //HPがなくなったら止まる
    noStroke();
    textSize(86);
    fill(255);
    text("GAME OVER !!", width/2, height/2);
    if(width/2<=mouseX && mouseX<=width/2+180 && height/2+20<=mouseY && mouseY<=height/2+80) {
      fill(255,0,0);
    } else {
 
      fill(255);
    }
    rect(width/2+90, height/2+50, 180, 60);
    textSize(50);
    fill(0);
    text("REPLAY", width/2, height/2+70);
  } else { //--------------------ゲーム
      Frame frame = leap.frame();               // Frame オブジェクトを宣言し、leap のフレームを入れる
      HandList hands = frame.hands();           // HandList オブジェクトを宣言し、frame 内の手（複数）の情報を取得
//      iBox = frame.interactionBox();            // InteractionBox を初期化

    background(0);
    stroke(255);
    noFill();
    rect(w2, h2, width-30, height-30);
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
    }
  }
  enemies = nextEnemies;
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
  if(mousePressed && mouseButton==RIGHT && state == false) {
    xx = mouseX;
    yy = mouseY;
    state = true;
//    enemies.add(new Enemy(mouseX, mouseY, d)); //右クリックで敵追加
  }
  
  //カーソルの表示
  for(int i = 0; i < hands.count(); i++) {  // 見つかった全ての手について
      Hand hand = hands.get(i);               // Hand オブジェクトを宣言し、i 番目の手を取得
      drawFingerTip(hand);                    // drawFingerTip 関数を呼ぶ
  }


  
  //HPと撃墜数の表示
  fill(255);
  textSize(26);
  text("HP", 10, 35);
  text(hp, 60, 35);
  text("HIT", 10, 60);
  text(hit, 60, 60);
  }
}

void drawFingerTip(Hand hand) {
    FingerList fingers = hand.fingers();        // FingerList オブジェクトに見つかった指の情報（複数）を入れる
    Finger finger = fingers.get(1);           // 指 i を取得（0:親指, 1:人差し指, 2:中指, 3:薬指, 4:小指）
    Vector tipPos = finger.tipPosition();     // その指の指先（tip）の位置を取得
//    Vector tipPosNorm = iBox.normalizePoint(tipPos, false);   // 標準化された座標値に変換
  float fx,fy; //指の位置
  fx = resizeX*tipPos.getX();
  fy = resizeY*tipPos.getZ();
  if(fx<= -w2|| fx>= w2 || fy<= -h2 || fy>= h2 ){
    float x=fx+ w2;
    float y=fy+ w2;
    if(fx<= -w2) x=0;
    if(fx>= w2) x=width;
    if(fy<= -h2) y=0;
    if(fy>= h2) y=height;  
    stroke(255);
    drawTriangle(x, y, 50);  // 横の位置、縦の位置、円の半径
  }else {
    if(finger.isExtended() == true) stroke(255-a,255,a);        // その指が伸びて（isExtended）いたら   
    else       stroke(255, 0, 0);                           // そうでなければ（伸びていなければ）                 // 塗りつぶし色を白に
    strokeWeight(5);
    line(fx+ w2, fy+16+ h2, fx+ w2, fy-16+ h2);    //撃つ方向
    line(fx-16+ w2, fy+ h2, fx+16+ w2,  fy+ h2);    //撃つ方向
  }
  fill(0,255,0);
  textSize(56);
  text(fx, width-50, 50); //-250~250がよさそう
  textSize(56);
  text(fy, width-50, 50); //-250~250がよさそう
    
}

class Myself{ //-------------------------ロケット
  
  int i=0;
  PVector loc;
  float size;
  float dmx,dmy,angle;
  int coolingTime;
  boolean isDead;
  
  Myself(){ 
    size = 40;
    loc = new PVector(width / 2, height - size / 2 - 10);
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
    pushMatrix();
    translate(loc.x, loc.y);//円の中心に座標を合わせます
    rotate(angle);
    drawTriangle(0, 0, size);  // 横の位置、縦の位置、円の半径
    fill(0,255,0);
    drawTriangle(0, -size/2, size/2);  // てっぺんを青く
    popMatrix();
  }
  
  void update(){
    isDead = false;
    float dmx = mouseX - loc.x;
    float dmy = mouseY - loc.y;
    if(dmx != 0 && dmy !=0){
      angle = angle+constrain(atan2(dmx,-dmy)-angle, -PI/12, PI/12);
    }
    dmx = constrain(dmx, -3, 3); //最小値-5最大値5
    loc.x += dmx;
    dmy = constrain(dmy, -3, 3); //最小値-5最大値5
    loc.y += dmy; 
    coolingTime++;
    if(mousePressed && mouseButton==LEFT && coolingTime >= 10){
      myBullets.add(new Bullet());
      coolingTime = 0;
    }
    for(Bullet b: eneBullets){
      if((loc.x - size / 2 <= b.loc.x && b.loc.x <= loc.x + size / 2)
         && (loc.y - size / 2 <= b.loc.y && b.loc.y <= loc.y + size / 2)){
        isDead = true;
        i = i++;
        b.isDead = true;
        break;
      }
    }
    for(Enemy e: enemies){
      if(abs(loc.x - e.loc.x) < size / 2 + e.size / 2 && abs(loc.y - e.loc.y) < size / 2 + e.size / 2){
        isDead = true;
        i = i++;
        e.isDead = true;
        hp = hp-100;
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
//  float vel;
  float size;
  int coolingTime;
  boolean isDead;
  
  Enemy(float x, float y, float dis){
    size = dis;
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
  }
  
  void display(){
//    fill(206,117,48);
a=a+da;
    if(a>255) {
      a=255;
      da = -1;
    }
    if(a<0) {
      a=0;
      da = 1;
    }
    fill(255-a,255,a);
    stroke(255-a,255,a);
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
  if(mouseButton==RIGHT){
    d = dist(xx, yy, mouseX, mouseY);
    enemies.add(new Enemy(xx, yy, d));
    state =false;
  }
  if(mouseX<=width/2+180&&mouseY<=height/2+80&&mouseX>=width/2&&mouseY>=height/2+20){
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

  }
}
