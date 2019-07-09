// SpaceShooting Sample / Written by n_ryota
//change

import processing.net.*;
import KinectPV2.KJoint;
import KinectPV2.*;
KinectPV2 kinect;
int bu = 0;
Client c;
Server s;
String input;
int j = 15;
int data[];
int shoot; //timing of shoot
int win = 0;
float sp;
int earth_e = 0;
//stop
// 変数定義
int PLAYER = 0, ENEMY = 1, EFFECT = 2;      // group定数(enum…)
Player player = new Player(0, 0, 0, 10);
int earth_x; int earth_z;// プレイヤー
ArrayList fighterList = new ArrayList();    // 戦闘機リスト（プレイヤー含む）
ArrayList bulletList = new ArrayList();     // 弾リスト
ArrayList effectList = new ArrayList(); 
ArrayList walllist = new ArrayList();
ArrayList earthlist = new ArrayList();
ArrayList<Enemy> enemies;    //change
// エフェクトリスト
float cameraShake = 0.0;                    // 現在のカメラの揺れ具合
int clearMillis = 0;                        // クリアタイム
PImage img;
PShape sphere;
int gameState=0;//ゲーム状態。データが送られ始めると1にする。
float startTime=-1000;//向こうからデータが送られ始めたとき（data[0]=1が何かしらの手違いで送られなかったときにはじまらないので改善したい）



//スタート用
final int start_num =1000;//最初の星の数。定数
int[] distance;
float[] angle;

int r ;


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
    PVector rot = new PVector(vel.z*radians(rotY),0,-vel.x*radians(rotY));
    vel.add(rot);
  }
  void accel(float speed) {
    vel.x += matrix.m02 * -speed;  vel.y += matrix.m12 * -speed;  vel.z += matrix.m22 * -speed;
    //float sp = player.vel.dist(new PVector(0,0,0));
    // vel.x = sp*cos(theta); vel.z = sp*sin(theta); 
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
    //発射時に今の角度を送る
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
   void update() {
    pos.x += vel.x; pos.y += vel.y; pos.z += vel.z;
    if(pos.z > 6400) pos.z -= 12800;
    if(pos.z < -6400) pos.z += 12800;
    if(pos.x > 12800) pos.x -= 25600;
    if(pos.x < -12800) pos.x += 25600;
 /*   if(pos.z > 3300 || pos.z < -3100 || pos.x < -6400 || pos.x > 6400){  //move to center
      pos.x = 0;
      pos.z = 0;
  }*/
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
  PVector loc;
  Effect(float _x, float _y, float _z, float _radius) {
    super(_x, _y, _z, _radius, EFFECT); 
    loc = new PVector(_x,_z);
}
  void drawShape() {
    damage(2);
    radius *= 1.04;
    fill(255, 64, 32, map(life, 0, 100, 0, 128));
    pushMatrix();
    translate((2/3)*(loc.x/2)+75*sin(radians(theta)),0,loc.z/2-75*cos(radians(theta)));
    sphere(radius);
    popMatrix();
  }
}
/*
class Wall extends Chara  {
  PVector loc;
  int a;
  Wall(float _x, float _y, float _z, float _radius,int _a) {
    super(_x, _y, _z, _radius, EFFECT); 
    loc = new PVector(_x,_y,_z);
    a = _a;
}
  void drawShape() {
    switch(a){
     case 0: 
       if(player.vel.z < 0) background(map(abs(player.pos.z-loc.z*2),0,1000,220,0 ));
       break;
     case 1:
       if(player.vel.z > 0) background(map(abs(player.pos.z-loc.z*2),0,1000,220,0 ));
       break;
     case 2:
       if(player.vel.x < 0) background(map(abs(player.pos.x-loc.x*2),0,1000,220,0 ));
       break;
     case 3:
       if(player.vel.x > 0) background(map(abs(player.pos.x-loc.x*2),0,1000,220,0 ));
       break;
   
   
    }
    //}
   
    fill(0, 64, 255,map(abs(player.pos.z-loc.z),0,1000,0,40));
    pushMatrix();
    translate(loc.x,loc.y,loc.z);
    
    if(radius == 0 && abs(player.pos.z-loc.z*2)<1000){
    fill(0, 64, 255,map(abs(player.pos.z-loc.z*2),0,1000,40,0));
    box(15000,15000,1);
    }else if(radius == 1 && abs(player.pos.x-loc.x*2)<1000) {
    fill(0, 64, 255,map(abs(player.pos.x-loc.x*2),0,1000,40,0));
    box(1,15000,15000);
    
    }
    popMatrix(); 
  }
}
*/
class Earth extends Chara  {
  PVector loc;
  Earth(float _x, float _y, float _z, float _radius) {
    super(_x, _y, _z, _radius, ENEMY); 
    loc = new PVector(_x,_y,_z);
}
  void drawShape() {
   pushMatrix();
   //translate(75*sin(radians(theta)),0,-75*cos(radians(theta)));//地球のkinect75座標系に変換されたx,z座標が送られてくる
   translate(loc.x,0,loc.z);
   shape(sphere);
   popMatrix();
  
  }
}

//change
class Enemy extends Chara{ //-------------------------------敵
  PVector loc;
  float size;
  int coolingTime;
  boolean isDead;
  int index;
  float scale;
  int type;
  Enemy(float x, float y, float z, float dis,int a,int d){
    super(x, y, z, dis, ENEMY);
    size = dis;
    index = a;
    type=d;//サイズが変わる強い敵かどうか
    if (x==0&&z==0){
      loc = new PVector(random(-2000,2000), random(-2000,2000));
    } else {
      loc = new PVector(x,z);
    }
    coolingTime = int(random(60));
    isDead = false;
  }
  
  void drawShape() {
    scale=(millis()-startTime)%2000;//サイズが変わる敵は時間で2倍まで（leapと揃える）
    if(scale>1000)scale=2000-scale;
    int colVar=(int)scale/20; //点滅させる用
    fill(0,220,0,155+colVar);
    pushMatrix();
    //translate(loc.x/2+75*sin(radians(theta)),loc.z/2-75*cos(radians(theta)));
    translate((2/3)*(loc.x/2)+75*sin(radians(theta)),0,loc.z/2-75*cos(radians(theta)));
    sphere(size*(1+(scale/1000)*type));//typeが0の時は変わらない
    popMatrix();
  }
  
 
}

//stop
int width=1600;
int height=840;
// 初期化//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void setup() {
  size(1600, 840, P3D);
  //change
  s = new Server(this,10000);
  kinect = new KinectPV2(this);
  kinect.enableSkeletonColorMap(true);
  kinect.enableColorImg(true);
  kinect.init();
  frameRate(60);
  //s = new Client(this, 10000);
  enemies = new ArrayList<Enemy>();
  //stop
  fighterList.add(player);
  //for(int i = 0; i < 15; i++){ //最初に敵を15体作っておく
   // for(Enemy enemy: enemies){
    //  enemy.drawShape();
    /*
    Wall wall1 = new Wall(0,0,-1550,0,0);
    walllist.add(wall1); 
    Wall wall2 = new Wall(0,0,1650,0,1);
    walllist.add(wall2);
    Wall wall3 = new Wall(-3200,0,0,0,2);
    walllist.add(wall3);
    Wall wall4 = new Wall(3200,0,0,0,3);
    walllist.add(wall4);
    */
  //  Enemy enemy1 = new Enemy(0,0,-1000,30,4);
   // enemies.add(enemy1);
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
  //地球用
  img = loadImage("earth.jpg");
  sphere=createShape(SPHERE,400);
  sphere.setTexture(img);
  sphere.setStrokeWeight(0);
  //スタート用
  distance=new int[start_num];
  angle=new float[start_num];
  
  for(int i =0;i<start_num;i++)
  {
  distance[i]=int(random(width/2)*sqrt(2));
  angle[i]=random(100);//0から100までのfloat
  }
  
  }
int drawcounter = 0;


// 毎フレームの進行と描画///////////////////////////////////////////////////////////////////////////////////////////////////////
void draw(){
  println(player.vel.x,player.vel.z,player.pos.x,player.pos.z);
    //sp = sqrt(pow(player.vel.x,2) + pow(player.vel.z,2));
    sp = player.vel.dist(new PVector(0,0,0));
    if(player.vel.z<0 && abs(player.pos.z+6400) <1000)  background(map(abs(player.pos.z+3200),0,1000,50,0 ),125);
    else if(player.vel.z>0 && abs(player.pos.z-6400) <1000) background(map(abs(player.pos.z-3200),0,1000,50,0 ),125);
    else if(player.vel.x<0 && abs(player.pos.x+12800) <1000) background(map(abs(player.pos.z+6400),0,1000,50,0 ),125);
    else if(player.vel.x>0 && abs(player.pos.x-12800) <1000) background(map(abs(player.pos.x-6400),0,1000,50,0 ),125);
    else background(0,125);
    
 
    //change
    ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();
    float t = millis() / 1000.0;
    //background(0,0,0,125);
    float scale=(millis()-startTime)%2000;//サイズが変わる敵は時間で2倍まで（leapと揃える）
    if(scale>1000)scale=2000-scale;
    
    if(gamestate==0)
    {
      fill(0,255,0,127);
      textSize(100);
      text("Loading…", width * 0.6, height * 0.8);
      for(int i =0;i<start_num;i++)
      {
        angle[i] += 0.01;
        fill(0,255,0,127);
        stroke(0,255,0);
        ellipse(
            distance[i] * cos(angle[i]) + width/2,
            distance[i] * sin(angle[i]) + height/2,
            0.5, 
            0.5);
        }
        c=s.available(); 
      if(c != null) 
    {
      input = c.readString();
      input = input.substring(0, input.indexOf("\n")); // Only up to the newline
      data = int(split(input, ' ')); 
      // Split values into an array
      //generate obstacle
      if(data[0] ==2)
      {
        println(data[0],data[1],data[2],data[3],data[4],data[5]);
        enemies.add(new Enemy(data[2],0,data[3],data[4],data[1],data[5]));

        if(data[1]==1)
         {
           gameState+=1;
           startTime=millis();
         }
        if(data[1]==15)player.accel(5);  //starting accel
      }

      }
    }
    
    
    if(gameState==1 && (millis()-startTime)/1000<=5)
    {      
      int L=10000;
      for(int i=0;i<start_num;i++)
      {
        distance[i] += 5;
        L=+100;
        stroke(0,255,0,127);
        strokeWeight(2);
        noFill();
        line(
            distance[i] * cos(angle[i]) + width/2,
            distance[i] * sin(angle[i]) + height/2,
            (distance[i]+L) * cos(angle[i]) + width/2,
            (distance[i]+L) * sin(angle[i]) + height/2);
        }
           c=s.available(); 
      if(c != null) 
    {
      input = c.readString();
      input = input.substring(0, input.indexOf("\n")); // Only up to the newline
      data = int(split(input, ' ')); 
      // Split values into an array
      //generate obstacle
      if(data[0] ==2)
      {
         println(data[0],data[1],data[2],data[3],data[4],data[5]);
         enemies.add(new Enemy(data[2],0,data[3],data[4],data[1],data[5]));
         if(data[1]==1)
         {
           gameState+=1;
           startTime=millis() / 1000.0;
         }
         if(data[1]==14)player.accel(5);  //starting accel
      }
      if(data[0] == 6)
         {
            println(data[0],data[1],data[2]);
            Earth earth = new Earth(data[1]/2,0,data[2]/2,0);
            earthlist.add(earth);
            earth_e = 1;
            earth_x = data[1];
            earth_z = data[2];
         }
    }
    }
    else
      {  
        c=s.available();
        if(c != null) 
        {
          input = c.readString();
          input = input.substring(0, input.indexOf("\n")); // Only up to the newline
          data = int(split(input, ' ')); 
          // Split values into an array
          //generate obstacle
          //reset
          if(data[0] ==3)
          {
             player.pos.x = 0;
             player.pos.z = 100;
             player.vel.x = 0;
             player.vel.z = 0;
             win = 0;
          } 
          if(data[0] ==2)
          {
             println(data[0],data[1],data[2],data[3],data[4],data[5]);
             enemies.add(new Enemy(data[2],0,data[3],data[4],data[1],data[5]));
             if(data[1]==1)
             {
               gameState+=1;
               startTime=millis() / 1000.0;
             }
             if(data[1]==14)player.accel(5);  //starting accel
          }
          // delete obstacle
          if(data[0] ==4)
          {
            println(data[0],data[1]);
            for(Enemy enemy: enemies)
            {
              if(enemy.index ==  data[1])
              {
                 enemy.isDead = true;
                 addExplosionEffect(enemy);
              }
            }
            if(data[2] == 1)
            {
              player.life -= 10;
            }
          }
         if(data[0] == 6)
         {
            println(data[0],data[1],data[2]);
            Earth earth = new Earth(data[1]/2,0,data[2]/2,0);
            earthlist.add(earth);
            earth_e = 1;
            earth_x = data[1];
            earth_z = data[2];
         }
         if(data[0] == 7)
         {
           win = 1;
          // Draw line using received coords
        }
        int x_send=int(player.pos.x/10);
        int y_send=int(player.pos.z/10);
        if(shoot==1)
        {
          int theta_send=int(theta);
          s.write(1 + " " + theta_send + " " +  "\n");
          delay(50);
          shoot = 0;
        }
        else if(drawcounter%3==0)
        {//弾をうっていない時のみ座標を送る
        s.write(0 + " " + x_send + " " + y_send + " " +  "\n");  
        delay(10);
        }
        //0:serve (x,y)
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
          if(chara.isDead == false &&  player.pos.dist(chara.loc) < 20000 ){
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
        /*for (int i=0;i<walllist.size();i++) {
          Wall wall = (Wall) walllist.get(i);
          wall.draw();
        }*/
        if(earth_e == 1){
          Earth earth = (Earth) earthlist.get(0);
          earth.draw();
        }
        //change
         for (int i = 0; i < skeletonArray.size(); i++) 
         {
            KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
            if (skeleton.isTracked()) 
            {
               KJoint[] joints = skeleton.getJoints();
               int j = joints[KinectPV2.JointType_HandRight].getState();
               if(j ==  KinectPV2.HandState_Open & bu > 60)
               {
                 player.shoot(30, 1);
                 shoot = 1;
                 //intじゃないとエラー？
                 bu=0;
               }
            }                   
          }
        bu += 1;
        //stop
        
        // 弾
        for (int i=0;i<bulletList.size();i++) 
        {
          Bullet bullet = (Bullet) bulletList.get(i);
          bullet.draw();
          for (int j=0;j<fighterList.size();j++) 
          {
            Fighter fighter = (Fighter) fighterList.get(j);
            if(bullet.isHit(fighter)) 
            {  // 弾が当たったらダメージ
              if(fighter==player) cameraShake += bullet.power * 0.5;  // プレイヤーがダメージを受けた場合は大きめに揺らす
              if(fighter.damage(bullet.power))
              {
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
        
        if(player.life>0 ) 
        {
          if(earth_e == 1)
          {
            float goaldis = player.pos.dist(new PVector(earth_x,0,earth_z));
            if(win ==1) 
            {
              background(0); 
              player.vel.x = 0;  player.vel.z = 0; 
              fill(255, 128);
              textSize(60);
              text("MISSION CLEAR", width/2, height/2 - 40);
              
              if(clearMillis==0) clearMillis = millis();
              text("TIME "+ nf(clearMillis*0.001, 1, 1) + "sec", width/2, height/2 + 30 );
            }
            else
            {
              //text("" + goaldis + " m", width/2, 30);
              float distanceEarth=sqrt((earth_x-player.pos.x)*(earth_x-player.pos.x)+(earth_z-player.pos.z)*(earth_z-player.pos.z));
              int distanceEarth_new=(int)distanceEarth;
              textSize(40);
              text("distance\n="+ distanceEarth_new ,0.1*width,0.75*height);
              text("" + player.pos.x + " " + player.pos.z, width/2, 30);
              textAlign(RIGHT, CENTER);
              text("life " + nf(player.life, 1, 0), width/3, height-30);
              rectMode(CORNER);
              noStroke();
              rect(20+width/3, height-34, map(player.life, 0, 100, 0, width/3), 5);
            }
          }
        }
           else 
           {
             textSize(60);
             text("GAME OVER", width/2, height/2);
             player.vel.x = 0;  player.vel.z = 0;
           }
          //機体の向き表現用
          stroke(0,200,0);
          drawDiamond(0.9*width,0.9*height,60,theta);
          //stroke(0,0,200);
          
          //機体の傾き表現用  
          stroke(0,200,0);
          drawcounter++;
        }
}

//↑コンパスのひし形を書く用
void drawDiamond(float x,float y,float r,float theta_d)
{
  float R;
  pushMatrix();
  translate(x,y);//x,yに移る
  beginShape();
  for(int i=0;i<4;i++)
  {
    if(i%2==0)R=r/5;//真ん中の2点
    else if(i==1)R=r/10;//向いていない方向は小さく
    else R=r;//向いている方向は大きく
    vertex(R*cos(radians(90*i+theta_d)),R*sin(radians(90*i+theta_d)));//点を打つ
  }
  endShape(CLOSE);//閉じてね
  popMatrix();
}

void arrow(float x,float y,float size,int type)//typeが1なら右側-1なら左側
{
  float R;
  pushMatrix();
  translate(x,y);//x,yに移る
  beginShape();
  float[]x_a={0.5, 2.5, 2.5, 4.0, 2.5, 2.5, 0.5};
  float[]y_a={0.5, 0.5, 1.0, 0.0, -1, -0.5, -0.5};
  for(int i=0;i<7;i++)
  {
    vertex(x_a[i]*size*type,y_a[i]*size*type);
  }
  endShape(CLOSE);//閉じてね
  popMatrix();
}

float theta=0;
// 毎フレームの入力//////////////////////////////////////////////////////////////////////////////////
void input(){
    float scale=(millis()-startTime)%2000;//サイズが変わる敵は時間で2倍まで（leapと揃える）
    if(scale>1000)scale=2000-scale;
    int colVar=(int)scale/20; //点滅させる用
    ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();
    //individual JOINTS
    for (int i = 0; i < skeletonArray.size(); i++)
    {
      KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
      if (skeleton.isTracked()) 
      {
        KJoint[] joints = skeleton.getJoints();
        
         float LeftDiff=joints[KinectPV2.JointType_ShoulderLeft].getY()-joints[KinectPV2.JointType_HandLeft].getY();
         float RightDiff=joints[KinectPV2.JointType_ShoulderRight].getY()-joints[KinectPV2.JointType_HandRight].getY();
         float InputLeft=constrain(map(abs(LeftDiff),50,500,0,1),0,0.2);//絶対値が50以上500以下なら[0,0.2]に正規化。50,500をキャリブレーションで設定出来るよう実装したい
         float InputRight=constrain(map(abs(RightDiff),50,500,0,1),0,0.2);//絶対値が50以上500以下なら[0,0.2]に正規化。50,500をキャリブレーションで設定出来るよう実装したい
         if(LeftDiff<0) 
         {
           InputLeft=-InputLeft;//LeftDiffが負ならばInputも負に
           stroke(0,200,0);
           fill(0,200,0,155+colVar);
         }
         if(RightDiff<0)
         {
           InputRight=-InputRight;
           stroke(0,200,0);
           fill(0,200,0,155+colVar);
         }
         if(InputLeft*InputRight<0)//左右の上下が反対なら回転
         {
           int arrow_direction=int(InputLeft/abs(InputLeft));//LeftDiffが負の時に-1にRightが負の時に1に
           arrow(0.1*width,0.9*height,15,arrow_direction);
           float Input=InputRight-InputLeft;
           player.roll(0.0f,Input, 0.0f);//y軸下向きなのでInputRightが正（右手が下がっている）なら時計周りに回転する
           theta -= Input;
         }
         //腕を両方あげるとスピードアップ(減速は保留）)
       
        
         if(InputLeft>0 && InputRight>0 && sp < 800)
        {
          player.accel(0.01);
        } else if(sp > 200){
         player.vel.mult(0.99);
         }        
      }
    }

}

// マウスボタンを押した瞬間
void mousePressed() {
  if(player.life>0 && mouseButton==LEFT) player.shoot(30, 1);
}

// 爆発エフェクトを追加
void addExplosionEffect(Chara chara) {
    Effect effect = new Effect(chara.pos.x, chara.pos.y, chara.pos.z, chara.radius);
    effectList.add(effect);
}

/*
// プレイヤー視点のカメラ
void setPlayerCamera() {
  player.updateMatrix();
  float sl = cameraShake * 0.01;
  PVector sp = new PVector(random_pm(sl), random_pm(sl), random_pm(sl));
  camera(player.pos.x-20*sin(radians(theta+180)), player.pos.y+10, player.pos.z-20*cos(radians(theta+180)),     // 位置
  //↑最初-z軸方向を向いているので
         player.pos.x-player.matrix.m02+sp.x, player.pos.y-player.matrix.m12+sp.y, player.pos.z-player.matrix.m22+sp.z, // 注視点
         player.matrix.m01, player.matrix.m11, player.matrix.m21); // アップベクトル
}
*/
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
void drawStars() 
{
  pushMatrix();
  translate(player.pos.x, player.pos.y, player.pos.z);
  int seed = int(random(1000)); randomSeed(0);
  float range = 500.0;
  PVector starPos = new PVector();
  for(int i=0; i<250; i++) 
  {
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