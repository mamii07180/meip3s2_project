// SpaceShooting Sample / Written by n_ryota
//change

import processing.net.*;
import KinectPV2.KJoint;
import KinectPV2.*;
KinectPV2 kinect;
int bu = 0;
Client c;
String input;
int j = 15;
int data[];

//stop
// 変数定義
int PLAYER = 0, ENEMY = 1, EFFECT = 2;      // group定数(enum…)
Player player = new Player(0, 0, 100, 10);  // プレイヤー
ArrayList fighterList = new ArrayList();    // 戦闘機リスト（プレイヤー含む）
ArrayList bulletList = new ArrayList();     // 弾リスト
ArrayList effectList = new ArrayList(); 

ArrayList<Enemy> enemies;    //change
// エフェクトリスト
float cameraShake = 0.0;                    // 現在のカメラの揺れ具合
int clearMillis = 0;                        // クリアタイム

// 3D空間に配置する基本オブジェクトクラス
class Chara {
  PMatrix3D matrix = new PMatrix3D();
  PVector pos = new PVector(), vel = new PVector();
  float radius, life;
  int group;
  Chara(float _x, float _y, float _z, float _radius, int _group) {
    pos.x = _x; pos.y = _y; pos.z = _z;
    radius = _radius; life = 100.0; group = _group;
  }
  void roll(float rotX, float rotY, float rotZ) {
    matrix.rotateY(radians(rotY));  matrix.rotateX(radians(rotX));  matrix.rotateZ(radians(rotZ));
  }
  void accel(float speed) {
    vel.x += matrix.m02 * -speed;  vel.y += matrix.m12 * -speed;  vel.z += matrix.m22 * -speed;
  }
  void lookAt(PVector vz) {
    PVector vx = vz.cross(new PVector(0,1,0)); vx.normalize();
    PVector vy = vz.cross(vx); vy.normalize();
    matrix.set(vx.x, vy.x, vz.x, pos.x, vx.y, vy.y, vz.y, pos.y, vx.z, vy.z, vz.z, pos.z, 0, 0, 0, 1);
  }
  void updateMatrix() {
    matrix.m03 = pos.x; matrix.m13 = pos.y; matrix.m23 = pos.z;
  }
  void update() {
    pos.x += vel.x; pos.y += vel.y; pos.z += vel.z;
  }
  boolean isHit(Chara chara) {
    if(group==chara.group) return false;
    else return pos.dist(chara.pos) <= radius + chara.radius;
  }
  boolean damage(float _damage) {
    life -= _damage;
    return life<=0.0;
  }
  void draw() {
    pushMatrix(); updateMatrix(); applyMatrix(matrix);
    drawShape();
    popMatrix();
    update();
  }
  void drawShape() {
    fill(255); box(radius);
  }
};

// 戦闘機クラス
class Fighter extends Chara  {
  Fighter(float _x, float _y, float _z, float _radius, int _group) { super(_x, _y, _z, _radius, _group); }
  Bullet shoot(int power, float radian) {
    Bullet bullet = new Bullet(pos.x, pos.y, pos.z, 7, group, power);
    bullet.matrix.set(matrix);
    if(radian>0) bullet.roll(random_pm(radian), random_pm(radian), random_pm(radian));  // 少し向きをランダムにばらけさせる
    bullet.accel(70);
    bulletList.add(bullet);
    return bullet;
  }
}

// プレイヤー戦闘機クラス
class Player extends Fighter {
  Player(float _x, float _y, float _z, float _radius) { super(_x, _y, _z, _radius, PLAYER); }
  void drawShape() {
    stroke(0, 255, 0, 64); strokeWeight(2); noFill();
    translate(0, 0, -10);
    box(radius, radius, radius*5);
    noStroke();
  }
}
//change
// 敵戦闘機クラス

//stop
// 弾クラス
class Bullet extends Chara  {
  int power;
  Bullet(float _x, float _y, float _z, float _radius, int _group, int _power) {
    super(_x, _y, _z, _radius, _group);
    power = _power;
  }
  void drawShape() {
    damage(0.5);
    if(group==PLAYER) stroke(0, 128, 255, 128);
    else stroke(255, 0, 0, 128);
    strokeWeight(4); fill(255);
    translate(0, radius*7, 0);
    box(radius, radius, radius*20);
  }
}

// エフェクトクラス
class Effect extends Chara  {
  Effect(float _x, float _y, float _z, float _radius) { super(_x, _y, _z, _radius, EFFECT); }
  void drawShape() {
    damage(2);
    matrix.scale(1.04);
    matrix.rotateX(0.1);
    fill(255, 64, 32, map(life, 0, 100, 0, 128));
    sphereDetail(7); sphere(radius);
  }
}



//change
class Enemy extends Chara{ //-------------------------------敵
  PVector loc;
  float size;
  int coolingTime;
  boolean isDead;
  int index;
  Enemy(float x, float y, float z, float dis,int a){
    super(x, y, z, dis, ENEMY);
    size = dis;
    index = a;
    if (x==0&&y==0){
      loc = new PVector(random(-2000,2000), random(-2000,2000));
    } else {
      loc = new PVector(x,y);
    }
    coolingTime = int(random(60));
    isDead = false;
  }
  
  void drawShape() {
    fill(0, 220, 0);
    pushMatrix();
    translate(loc.x,loc.y);
    sphere(size);
    popMatrix();
  }
  
 
}

//stop

// 初期化
void setup() {
  size(640, 480, P3D);
  //change
  c = new Client(this,"127.0.0.1",12345);
  kinect = new KinectPV2(this);
  kinect.enableSkeletonColorMap(true);
  kinect.enableColorImg(true);
  kinect.init();
  frameRate(60);
  enemies = new ArrayList<Enemy>();
  //stop
  fighterList.add(player);
  //for(int i = 0; i < 15; i++){ //最初に敵を15体作っておく
   // for(Enemy enemy: enemies){
    //  enemy.drawShape();
     
   // }
  //敵のリスト更新
  //  ArrayList<Enemy> nextEnemies = new ArrayList<Enemy>();
   // for(Enemy enemy: enemies){
    //    nextEnemies.add(enemy);
   // }
   // enemies = nextEnemies;
    //  enemies.add(new Enemy(0,0,0,random(25)*2,i));
 // }
  //textFont( createFont("Lucida Console", 20) );
}

// 毎フレームの進行と描画
void draw(){
  background(0);
  //change
  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();
  
  if(c.available() > 0) {
    input = c.readString();
    input = input.substring(0, input.indexOf("\n")); // Only up to the newline
    data = int(split(input, ' ')); 
    // Split values into an array
    //generate obstacle
    if(data[0] ==2){
      println(data[0],data[1],data[2],data[3],data[4]);
     enemies.add(new Enemy(data[2],data[3],0,data[4],data[1]));
    } 
    // delete obstacle
    if(data[0] ==4){
      println(data[0],data[1]);
      for(Enemy enemy: enemies){
        if(enemy.index ==  data[1]){
           enemy.isDead = true;
        }
    } 
    }
    // Draw line using received coords
  }
  //stop
  // 宇宙背景、塵
  setLights();
  setPlayerCamera();
  drawStars();

  // プレイヤーと敵
  for (int i=0;i<fighterList.size();i++) {
    Fighter chara = (Fighter) fighterList.get(i);
    chara.draw();
  }
  for(int i=0;i<enemies.size();i++) {
    Enemy chara = (Enemy) enemies.get(i);
    if(chara.isDead == false){
    chara.draw();
    }
  }
  // エフェクト
  noLights();
  for (int i=0;i<effectList.size();i++) {
    Effect effect = (Effect) effectList.get(i);
    effect.draw();
    if(effect.life<=0) effectList.remove(i--); // 寿命で消滅
  }
  //change
   for (int i = 0; i < skeletonArray.size(); i++) {

    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);

    if (skeleton.isTracked()) {

      KJoint[] joints = skeleton.getJoints();

     
     int j = joints[KinectPV2.JointType_HandRight].getState();
     if(j ==  KinectPV2.HandState_Open & bu > 60) {
           println("shoot");
           player.shoot(30, 1);
           bu = 0;
     } 
     
    }

  }
  bu += 1;
  //stop
  
  // 弾
  for (int i=0;i<bulletList.size();i++) {
    Bullet bullet = (Bullet) bulletList.get(i);
    bullet.draw();
    for (int j=0;j<fighterList.size();j++) {
      Fighter fighter = (Fighter) fighterList.get(j);
      if(bullet.isHit(fighter)) {  // 弾が当たったらダメージ
        if(fighter==player) cameraShake += bullet.power * 0.5;  // プレイヤーがダメージを受けた場合は大きめに揺らす
        if(fighter.damage(bullet.power)) {
          fighterList.remove(j--);      // ライフが尽きているので削除
          addExplosionEffect(fighter);  // 爆発エフェクト
          cameraShake += 1.0;           // カメラを少し揺らす
        }
        bullet.life = 0;
        break;
      }
    }
    if(bullet.life<=0) bulletList.remove(i--); // 寿命で消滅
  }
   
  // 情報表示
  camera();
  noLights();
  textMode(SCREEN); textSize(20); textAlign(CENTER, TOP);
  if(player.life>30) fill(0, 255, 0, 128);
  else fill(255, 0, 0, 128);
  //gameover
  input();
  cameraShake *= 0.95;
}

// 毎フレームの入力
void input(){
  if(keyPressed && key=='1') {
  if(mouseX>0 && mouseX<width && mouseY>0 && mouseY<height) {
    float rotYLevel = map(mouseX, 0, width, -1, 1);
    float rotXLevel = map(mouseY, 0, height, -1, 1);
    player.roll(rotXLevel * abs(rotXLevel) * 3.0, -rotYLevel * abs(rotYLevel) * 3.0, 0.0f);
  }
  }
  if(player.life>0) {
    if((keyPressed && key==' ') || (mousePressed && mouseButton==RIGHT)) player.accel(0.04);
    else player.vel.mult(0.98);
  }
}


// マウスボタンを押した瞬間
void mousePressed() {
  if(player.life>0 && mouseButton==LEFT) player.shoot(30, 1);
}

// 爆発エフェクトを追加
void addExplosionEffect(Chara chara) {
  for(int i=0; i<3; i++) {
    Effect effect = new Effect(chara.pos.x, chara.pos.y, chara.pos.z, chara.radius);
    effect.vel.set(random_pm(3), random_pm(3), random_pm(3));
    effectList.add(effect);
  }
}

// プレイヤー視点のカメラ
void setPlayerCamera() {
  player.updateMatrix();
  float sl = cameraShake * 0.01;
  PVector sp = new PVector(random_pm(sl), random_pm(sl), random_pm(sl));
  camera(player.pos.x, player.pos.y, player.pos.z,     // 位置
         player.pos.x-player.matrix.m02+sp.x, player.pos.y-player.matrix.m12+sp.y, player.pos.z-player.matrix.m22+sp.z, // 注視点
         player.matrix.m01, player.matrix.m11, player.matrix.m21); // アップベクトル
}

// ライト設定
void setLights() {
  ambientLight(50, 50, 70); 
  directionalLight(255, 255, 255, 0, 1, 0); 
}

// aをbで割った余りを返す
float modulo(float a, float b) {
  return a - floor(a / b) * b;
}

// ±rangeの乱数を返す
float random_pm(float range) {
  return random(-range, range);
}

// 宇宙背景、塵の描画
void drawStars() {
  pushMatrix();
  translate(player.pos.x, player.pos.y, player.pos.z);
  int seed = int(random(1000)); randomSeed(0);
  float range = 500.0;
  PVector starPos = new PVector();
  for(int i=0; i<250; i++) {
    // 遠くの星々
    strokeWeight(int(random(1,3))); stroke(random(128,255));
    starPos.set(random_pm(range*100), random_pm(range*100), random_pm(range*100));
    line(starPos.x, starPos.y, starPos.z, starPos.x, starPos.y, starPos.z);

    // 近くの塵（プレイヤーのまわりに常にあるようにループさせる）
    starPos.set(random(range), random(range), random(range));
    starPos.x = modulo(-player.pos.x + starPos.x, range) - range * 0.5;
    starPos.y = modulo(-player.pos.y + starPos.y, range) - range * 0.5;
    starPos.z = modulo(-player.pos.z + starPos.z, range) - range * 0.5;
    line(starPos.x, starPos.y, starPos.z, starPos.x-player.vel.x*(range*0.001), starPos.y-player.vel.y*(range*0.001), starPos.z-player.vel.z*(range*0.001));
  }
  randomSeed(seed);

  // 惑星
  noStroke();
  fill(0, 0, 255);
  translate(-20000,0,-30000);
  sphereDetail(30); sphere(20000);
  popMatrix();
}