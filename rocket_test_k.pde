/**
* simple 2D shooter game
*
* @author aa_debdeb
* @date 2016/08/30
*/
//change
import KinectPV2.KJoint;
import KinectPV2.*;
KinectPV2 kinect;
int bu = 0;
//end
Myself myself;
ArrayList<Enemy> enemies;
ArrayList<Bullet> myBullets;
ArrayList<Bullet> eneBullets; //相手の弾（今回はいらない）

void setup(){
  size(1280, 1280);
  //change
  kinect = new KinectPV2(this);
  kinect.enableSkeletonColorMap(true);
  kinect.enableColorImg(true);
  kinect.init();
  frameRate(60);
  //end
  rectMode(CENTER);
  myself = new Myself();
  enemies = new ArrayList<Enemy>();
  myBullets = new ArrayList<Bullet>();
  eneBullets = new ArrayList<Bullet>(); 
  for(int i = 0; i < 10; i++){
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
      enemies.add(new Enemy(0,0));
  //  }
  }
}

void draw(){
  background(0);
  
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
  if(mousePressed && mouseButton==RIGHT) {
    enemies.add(new Enemy(mouseX, mouseY)); //右クリックで敵追加
  }
}

class Myself{ //-------------------------ロケット
  
  PVector loc;
  float size;
  float angle=0.0;
  int coolingTime;
  boolean isDead;
  
  Myself(){ 
    size = 25;
    loc = new PVector(width / 2, height - size / 2 - 10);
    coolingTime = 0;
    isDead = false;
  }
  
  void display(){
    if(isDead){
      fill(255, 255, 0);
      stroke(0, 255, 0); 
    } else {
      fill(255,0,0);
      stroke(255,0, 0);
    }
    pushMatrix();
    translate(loc.x, loc.y);//円の中心に座標を合わせます
    rotate(angle);
    drawTriangle(0, 0, size);  // 横の位置、縦の位置、円の半径
    popMatrix();
  }
  
  void update(){
    //change
    ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();
    //stop
    isDead = false;
    float dmx = mouseX - loc.x;
    dmx = constrain(dmx, -3, 3); //最小値-5最大値5
    loc.x += dmx;
    float dmy = mouseY - loc.y;
    dmy = constrain(dmy, -3, 3); //最小値-5最大値5
    loc.y += dmy; 
    angle=atan2(dmx, dmy);

    coolingTime++;
    if(mousePressed && mouseButton==LEFT && coolingTime >= 10){
      myBullets.add(new Bullet());
      coolingTime = 0;
    }
    
    //change
    for (int i = 0; i < skeletonArray.size(); i++) {

    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);

    if (skeleton.isTracked()) {

      KJoint[] joints = skeleton.getJoints();

     
     int j = joints[KinectPV2.JointType_HandRight].getState();
     if(j ==  KinectPV2.HandState_Open && coolingTime > 10) {
           println("shoot");
           myBullets.add(new Bullet());
           coolingTime = 0;
           
     } 
     
    }

  }
  //end
    for(Bullet b: eneBullets){
      if((loc.x - size / 2 <= b.loc.x && b.loc.x <= loc.x + size / 2)
         && (loc.y - size / 2 <= b.loc.y && b.loc.y <= loc.y + size / 2)){
        isDead = true;
        b.isDead = true;
        break;
      }
    }
    for(Enemy e: enemies){
      if(abs(loc.x - e.loc.x) < size / 2 + e.size / 2 && abs(loc.y - e.loc.y) < size / 2 + e.size / 2){
        isDead = true;
        e.isDead = true;
        break;
      }
    }
  }
}

class Bullet{ //-------------------------銃
  
  PVector loc;
  float vel;
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
    line(loc.x, loc.y, loc.x, loc.y + vel);    
  }

  void update(){
    loc.y += vel;
    if((vel > 0 && loc.y > height) || (vel < 0 && loc.y < 0)){
      isDead = true;
    }
  }  
}

class Enemy{
  
  PVector loc;
  float vel;
  float size;
  int coolingTime;
  boolean isDead;
  
  Enemy(float x, float y){
//  Enemy(){
    size = random(25)*2;
    if (x==0&&y==0){
      loc = new PVector(random(width), random(height));
    } else {
      loc = new PVector(x,y);
    }
    vel = 3;
    coolingTime = int(random(60));
    isDead = false;
  }
  
  void display(){
    fill(206,117,48);
    stroke(206,117,48);
    ellipse(loc.x, loc.y, size, size);
    //rect(loc.x, loc.y, size, size);
  }

  void update(){
//    loc.y = vel;
    if(loc.y > height){
      isDead = true;
    }
    coolingTime++;
    if(coolingTime >= 60){
      eneBullets.add(new Bullet(this));
      coolingTime = 0;
    }
    for(Bullet b: myBullets){ //あたり判定
      if((loc.x - size / 2 <= b.loc.x && b.loc.x <= loc.x + size / 2)
         && (loc.y - size / 2 <= b.loc.y && b.loc.y <= loc.y + size / 2)){
        isDead = true;
        b.isDead = true;
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


/*
if (mouseButton==RIGHT) {
    ellipse(mouseX, mouseY, 20, 20);
}*/