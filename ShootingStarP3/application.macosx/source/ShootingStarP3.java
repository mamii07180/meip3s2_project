import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Comparator; 
import java.util.Arrays; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class ShootingStarP3 extends PApplet {

// ShootingStarP3 (c)2015 NISHIDA Ryota - http://dev.eyln.com (zlib License)

// \u6226\u95d8\u6a5f\u30ea\u30b9\u30c8\uff08\u30d7\u30ec\u30a4\u30e4\u30fc\u542b\u3080\uff09\u3001\u5f3e\u30ea\u30b9\u30c8\u3001\u30a8\u30d5\u30a7\u30af\u30c8\u30ea\u30b9\u30c8
ArrayList<Fighter> fighterList = new ArrayList<Fighter>();
ArrayList<Bullet> bulletList = new ArrayList<Bullet>();
ArrayList<Effect> effectList = new ArrayList<Effect>();

// \u30b0\u30eb\u30fc\u30d7\u5206\u985e\u7528\u306e\u5b9a\u6570
final int PLAYER = 0;
final int ENEMY = 1;
final int EFFECT = 2; 

Player player;              // \u30d7\u30ec\u30a4\u30e4\u30fc\u6226\u95d8\u6a5f(\u81ea\u6a5f)
MQOModel enemyModel;        // \u6575\u30e2\u30c7\u30eb
MQOModel planetModel;       // \u60d1\u661f\u30e2\u30c7\u30eb
PImage earthImg;
PImage explosionImg;
float cameraShake = 0.0f;    // \u73fe\u5728\u306e\u30ab\u30e1\u30e9\u306e\u63fa\u308c\u5177\u5408
int clearTime = 0;          // \u30af\u30ea\u30a2\u30bf\u30a4\u30e0

int framePrevTime = 0;      // \u524d\u30d5\u30ec\u30fc\u30e0\u306e\u6642\u9593
float frameStepBase = 1;    // 1\u30d5\u30ec\u30fc\u30e0\u3067\u9032\u3080\u91cf\u306e\u8a08\u7b97\u7528
int frameStep = 1;          // 1\u30d5\u30ec\u30fc\u30e0\u3067\u9032\u3080\u91cf

float screenScale = 1.0f;   // \u753b\u9762\u62e1\u5927\u7387
int baseWidth = 640;        // \u57fa\u6e96\u753b\u9762\u306e\u6a2a\u5e45
int baseHeight = 480;       // \u57fa\u6e96\u753b\u9762\u306e\u7e26\u5e45

// Android\u74b0\u5883\u306e\u5834\u5408true\u3092\u8fd4\u3059
public boolean isAndroid() {
  return System.getProperty("java.vendor").equalsIgnoreCase("The Android Project");
}

//----------------------------------------------
// \u521d\u671f\u5316
public void setup() {
  //size(640, 480, P3D);
  //size(800, 600, P3D);
  

  if(isAndroid()) {
    orientation(LANDSCAPE);
  }

  screenScale = min(width / (float)baseWidth, height / (float)baseHeight);
  textFont( createFont("Lucida Console", 20) );

  // \u30e2\u30c7\u30eb\u306e\u8aad\u307f\u8fbc\u307f
  enemyModel = new MQOModel(this, "enemy.mqo");
  enemyModel.setShading(MQOModel.SHADING_FLAT);
  
  earthImg = loadImage("earth.jpg");
  explosionImg = loadImage("explosion.png");

  resetStage();  // \u30b9\u30c6\u30fc\u30b8\u306e\u521d\u671f\u5316
  framePrevTime = millis();
}

//----------------------------------------------
// \u30b9\u30c6\u30fc\u30b8\u306e\u521d\u671f\u5316
public void resetStage() {
  // \u30e6\u30cb\u30c3\u30c8\u3092\u3059\u3079\u3066\u7834\u68c4
  fighterList.clear();
  effectList.clear();
  bulletList.clear();

  // \u6226\u95d8\u6a5f\u306e\u767b\u9332
  fighterList.add(player = new Player(0, 0, 100, 10));
  player.lookAtPos(new PVector(-200, 0, 0.0f));
  for(int i=0; i<10; i++) {
    PVector pos = new PVector(random(-5000, -4000), random(-2000, 2000), random(-2000, 20000));
    fighterList.add(new Enemy(enemyModel, pos.x, pos.y, pos.z, 150));
  }

  clearTime = 0;
}

//----------------------------------------------
// \u63cf\u753b
public void draw(){
  // \u30e6\u30cb\u30c3\u30c8\u9032\u884c
  updateFrameStep();
  for(int i=0; i<frameStep; i++) {
    update();
  }
  
  // \u5b87\u5b99\u80cc\u666f\u306e\u63cf\u753b
  background(0);
  scale(screenScale);
  noLights();
  setUnitCamera(player);
  drawStars();
  setLights();

  // \u30d7\u30ec\u30a4\u30e4\u30fc\u3068\u6575\u306e\u63cf\u753b
  for(Fighter fighter : fighterList) {
    fighter.draw();
  }

  // \u30a8\u30d5\u30a7\u30af\u30c8\u306e\u63cf\u753b
  hint(DISABLE_DEPTH_TEST);
  blendMode(ADD);
  noLights();
  for(Effect effect : effectList) {
    effect.draw();
  }

  // \u5f3e\u306e\u63cf\u753b
  for(Bullet bullet : bulletList) {
    bullet.draw();
  }
  blendMode(BLEND);

  // \u60c5\u5831\u8868\u793a
  camera();
  pushMatrix();
  scale(screenScale);
  noLights();
  drawInfo();
  popMatrix();

  drawFilter();

  hint(ENABLE_DEPTH_TEST);
  
  if(keyPressed && key=='s') save("ssx" + frameCount + ".png");
}

//----------------------------------------------
// \u30d7\u30ed\u30b8\u30a7\u30af\u30bf\u30fc\u6295\u5f71\u5148\u306e\u8272\u5473\u3068\u5f62\u72b6\u306b\u3042\u308f\u305b\u3066\u753b\u9762\u3092\u52a0\u5de5
public void drawFilter() {
  /*
  // \u7dd1\u8272\u6210\u5206\u3092\u6e1b\u3089\u3059
  blendMode(MULTIPLY);
  fill(255, 180, 255, 255);
  rect(0, 0, width, height);
  blendMode(BLEND);
  */

  // \u4e38\u304f\u7e01\u53d6\u3063\u3066\u307e\u308f\u308a\u3092\u6697\u304f\u3059\u308b
  noFill();
  stroke(0);
  strokeWeight(height/2);
  ellipse(width/2, height/2, height*2.0f, height*1.8f); 
}

//----------------------------------------------
// \u5b9f\u969b\u306b\u9032\u3081\u308b\u30d5\u30ec\u30fc\u30e0\u6570\u3092\u8a08\u7b97
// frameRate\u304c60\u3088\u308a\u5c0f\u3055\u304f\u306a\u3063\u3066\u3082\u9032\u884c\u901f\u5ea6\u304c\u4e00\u5b9a\u306b\u306a\u308b\u3088\u3046\u306b
// frameStep\u3092\u8a08\u7b97\u3059\u308b(frameRate\u304c30\u306e\u3068\u304dframeStep\u306f2)
public void updateFrameStep() {
  int nowTime = millis();
  frameStepBase += (nowTime - framePrevTime) / (1000 / 60.0f);  // \u5b9f\u969b\u4f55\u30d5\u30ec\u30fc\u30e0\u5206\u306e\u6642\u9593\u304c\u7d4c\u904e\u3057\u305f\u304b\u8a08\u7b97\u3057\u3066\u30d9\u30fc\u30b9\u306b\u52a0\u7b97
  frameStep = PApplet.parseInt(frameStepBase);  // \u4eca\u56de\u9032\u3081\u308b\u30d5\u30ec\u30fc\u30e0\u6570\u3092\u6574\u6570\u3067\u8a2d\u5b9a
  frameStepBase -= frameStep;      // \u4eca\u56de\u9032\u3081\u308b\u5206\u306f\u30d9\u30fc\u30b9\u304b\u3089\u53d6\u308a\u9664\u304f(\u5c0f\u6570\u70b9\u4ee5\u4e0b\u306e\u307f\u6b8b\u308b)
  framePrevTime = nowTime;
}

//----------------------------------------------
// \u9032\u884c
public void update() {
  // \u30d7\u30ec\u30a4\u30e4\u30fc\u3068\u6575
  for(Fighter fighter : fighterList) {
    fighter.update();
  }

  // \u30a8\u30d5\u30a7\u30af\u30c8
  for (int i=0;i<effectList.size();i++) {
    Effect effect = effectList.get(i);
    effect.update();
    if(effect.life<=0) effectList.remove(i--); // \u5bff\u547d\u3067\u6d88\u6ec5
  }

  // \u5f3e
  for (int i=0;i<bulletList.size();i++) {
    Bullet bullet = bulletList.get(i);
    bullet.update();
    for (int j=0;j<fighterList.size();j++) {
      Fighter fighter = (Fighter) fighterList.get(j);
      if(bullet.isHit(fighter)) {  // \u5f3e\u304c\u5f53\u305f\u3063\u305f\u3089\u30c0\u30e1\u30fc\u30b8
        if(fighter==player) cameraShake += bullet.power * 0.5f;  // \u30d7\u30ec\u30a4\u30e4\u30fc\u304c\u30c0\u30e1\u30fc\u30b8\u3092\u53d7\u3051\u305f\u5834\u5408\u306f\u5927\u304d\u3081\u306b\u63fa\u3089\u3059
        if(fighter.damage(bullet.power)) {
          fighterList.remove(j--);      // \u30e9\u30a4\u30d5\u304c\u5c3d\u304d\u3066\u3044\u308b\u306e\u3067\u524a\u9664
          addExplosionEffect(fighter);  // \u7206\u767a\u30a8\u30d5\u30a7\u30af\u30c8
          cameraShake += 1.0f;           // \u30ab\u30e1\u30e9\u3092\u5c11\u3057\u63fa\u3089\u3059
        }
        bullet.life = 0;
        break;
      }
    }
    if(bullet.life<=0) bulletList.remove(i--); // \u5bff\u547d\u3067\u6d88\u6ec5
  }

  inputUnit(player);
  cameraShake *= 0.95f;
}

///----------------------------------------------
// \u60c5\u5831\u8868\u793a
public void drawInfo() {
  textSize(20);
  textAlign(CENTER, CENTER);
  int centerX = PApplet.parseInt(width / screenScale) / 2;
  int centerY = PApplet.parseInt(height / screenScale) / 2;

  // \u30b3\u30af\u30d4\u30c3\u30c8\u7528\u4e38\u30d5\u30ec\u30fc\u30e0
  noFill();
  stroke(220);
  strokeWeight(3);
  ellipse(centerX, centerY, baseHeight*0.4f, baseHeight*0.4f); 
  strokeWeight(10);
  ellipse(centerX, centerY*1.1f, baseHeight*0.88f, baseHeight*0.88f); 

  // \u30e9\u30a4\u30d5\u306a\u3069
  if(player.life > 30) fill(0, 255, 0, 255);  // \u751f\u304d\u3066\u308b\u3068\u304d\u306f\u7dd1
  else fill(255, 0, 0, 255);                  // \u6b7b\u3093\u3067\u308b\u3068\u304d\u306f\u8d64

  if(player.life>0) {
    int enemyNum = fighterList.size()-1;
    if(enemyNum==0) {  // \u6575\u306e\u6570\u304c0\u306e\u3068\u304d\u306f\u30af\u30ea\u30a2\u753b\u9762
      clearDepth();
      textSize(40);
      text("MISSION CLEAR", centerX, baseHeight / 2 - 40);
      if(clearTime==0) clearTime = millis();
      text("TIME "+ nf(clearTime * 0.001f, 1, 1) + "sec", centerX, baseHeight/2 + 30 );
    } else {           // \u901a\u5e38\u306f\u6b8b\u308a\u306e\u6575\u306e\u6570\u3092\u8868\u793a
      text("" + enemyNum + " enemy" + (enemyNum>1 ? "s " : "" ), centerX, 30);
      textAlign(RIGHT, CENTER);
      text("life " + nf(player.life, 1, 0), baseWidth/2+10, baseHeight-90);
      rectMode(CORNER);
      noStroke();
      rect(30+baseWidth/2, baseHeight-92, map(player.life, 0, 100, 0, baseWidth/4), 8);
    }
  } else {
    if(clearTime==0) clearTime = -1;
    textSize(40);
    text("GAME OVER", centerX, baseHeight/2);
  }
  if(clearTime!=0) {
    // \u518d\u30d7\u30ec\u30a4\u30dc\u30bf\u30f3\u3092\u4e0b\u90e8\u306b\u8868\u793a
    noStroke();
    rect(0, height / screenScale - 60, width / screenScale, 60);
    fill(0);
    textSize(20);
    text("RETRY", centerX, height / screenScale - 30);
  }
}

//----------------------------------------------
// \u6bce\u30d5\u30ec\u30fc\u30e0\u306e\u5165\u529b
public void inputUnit(Unit unit) {
  if(mouseX > 0 && mouseX < width && mouseY > 0 && mouseY < height) {
    // \u56de\u8ee2
    float rotYLevel = map(mouseX, 0, width, -1, 1);
    float rotXLevel = map(mouseY, 0, height, -1, 1);
    unit.rotate(rotXLevel * abs(rotXLevel) * 3.0f, -rotYLevel * abs(rotYLevel) * 3.0f, 0.0f);
  }
  if(player.life > 0) {
    if((keyPressed && key==' ') || mousePressed) unit.accel(0.04f); // \u52a0\u901f
    else unit.vel.mult(0.98f);  // \u5f90\u3005\u306b\u6e1b\u901f
  }
}

//----------------------------------------------
// \u30de\u30a6\u30b9\u30dc\u30bf\u30f3\u3092\u62bc\u3057\u305f\u77ac\u9593
public void mousePressed() {
  if(player.life > 0) player.shoot(30, 1);
}

//----------------------------------------------
// \u30de\u30a6\u30b9\u30dc\u30bf\u30f3\u3092\u96e2\u3057\u305f\u77ac\u9593
public void mouseReleased() {
  if(clearTime != 0 && mouseY > height - 60 * screenScale) resetStage();
}

//----------------------------------------------
// \u7206\u767a\u30a8\u30d5\u30a7\u30af\u30c8\u3092\u8ffd\u52a0
public void addExplosionEffect(Unit unit) {
  for(int i=0; i<3; i++) {
    Effect effect = new Effect(unit.pos.x, unit.pos.y, unit.pos.z, unit.radius);
    effect.vel.set(PVector.mult(PVector.random3D(), 10.0f));
    effectList.add(effect);
  }
}

//----------------------------------------------
// \u30e6\u30cb\u30c3\u30c8\u8996\u70b9\u306e\u30ab\u30e1\u30e9
public void setUnitCamera(Unit unit) {
  unit.updateMatrix();
  PVector sp = PVector.mult(PVector.random3D(), cameraShake * 0.01f); // \u30ab\u30e1\u30e9\u63fa\u3089\u3057\u7528\u306e\u30d9\u30af\u30c8\u30eb
  PVector vz = unit.getForward();
  PVector vy = unit.getUp();
  float backLevel = unit.radius * -0.1f; // \u4e00\u4eba\u79f0\u8996\u70b9\u306b\u8fd1\u3044\u4f4d\u7f6e\u306b\u3059\u308b
  camera(unit.pos.x + vz.x * backLevel, unit.pos.y + vz.y * backLevel, unit.pos.z + vz.z * backLevel, // \u4f4d\u7f6e
         unit.pos.x + sp.x, unit.pos.y + sp.y, unit.pos.z + sp.z, // \u6ce8\u8996\u70b9
         vy.x, vy.y, vy.z); // \u30a2\u30c3\u30d7\u30d9\u30af\u30c8\u30eb
  perspective(radians(60), PApplet.parseFloat(width)/height, 5.0f, 10000.0f); // \u753b\u89d2\u3068\u9060\u8fd1\u306e\u63cf\u753b\u7bc4\u56f2\u3092\u8a2d\u5b9a
}

//----------------------------------------------
// \u30e9\u30a4\u30c8\u8a2d\u5b9a
public void setLights() {
  ambientLight(50, 50, 70); 
  directionalLight(255, 255, 255, 0, 1, 0); 
}

//----------------------------------------------
// \u5b87\u5b99\u80cc\u666f\u306e\u63cf\u753b
public void drawStars() {
  pushMatrix();
  translate(player.pos.x, player.pos.y, player.pos.z);

  int seed = PApplet.parseInt(random(1000)); randomSeed(0);
  float range = 500.0f;
  PVector starPos = new PVector();
  for(int i=0; i<150; i++) {
    // \u9060\u304f\u306e\u661f\u3005
    strokeWeight(PApplet.parseInt(random(1,3) * screenScale)); stroke(random(128,255));
    starPos.set(random(-100, 100), random(-100, 100), random(-100, 100));
    point(starPos.x, starPos.y, starPos.z);

    // \u8fd1\u304f\u306e\u5875\uff08\u30d7\u30ec\u30a4\u30e4\u30fc\u306e\u307e\u308f\u308a\u306b\u5e38\u306b\u3042\u308b\u3088\u3046\u306b\u30eb\u30fc\u30d7\u3055\u305b\u308b\uff09
    starPos.set(random(range), random(range), random(range));
    starPos.x = modulo(-player.pos.x + starPos.x, range) - range * 0.5f;
    starPos.y = modulo(-player.pos.y + starPos.y, range) - range * 0.5f;
    starPos.z = modulo(-player.pos.z + starPos.z, range) - range * 0.5f;
    line(starPos.x, starPos.y, starPos.z,
      starPos.x - player.vel.x * (range * 0.001f) + 0.001f,
      starPos.y - player.vel.y * (range * 0.001f),
      starPos.z - player.vel.z * (range * 0.001f));
  }
  randomSeed(seed);

  // \u60d1\u661f
  noStroke();
  translate(0,0,-300);
  imageMode(CENTER);
  image(earthImg, 0, 0, 1000, 1000);

  popMatrix();

  // \u6df1\u5ea6\u30d0\u30c3\u30d5\u30a1\u3092\u30af\u30ea\u30a2\u3057\u3066\u4e0a\u306b\u63cf\u753b\u3067\u304d\u308b\u3088\u3046\u306b\u3059\u308b
  clearDepth();
}

//----------------------------------------------
// \u6df1\u5ea6\u30d0\u30c3\u30d5\u30a1\u3092\u30af\u30ea\u30a2\u3059\u308b
public void clearDepth() {
  PGraphicsOpenGL pgl = (PGraphicsOpenGL)g;
  PGL gl = pgl.beginPGL();
  gl.clear(PGL.DEPTH_BUFFER_BIT);
  pgl.endPGL();
}

//----------------------------------------------
// a\u3092b\u3067\u5272\u3063\u305f\u4f59\u308a\u3092\u8fd4\u3059
public float modulo(float a, float b) {
  return a - floor(a / b) * b;
}
/*******************************************************************************
 * MQO Loader - loads, displays, MQO models for Processing
 *  ver.0.2.3 - by NISHIDA Ryota (http://dev.eyln.com/)
 *
 * MQO FileFormat
 * http://www.metaseq.net/metaseq/format.html
 ********************************************************************************/




class MQOTex {
  String name;
  PImage texture;
  MQOTex(String name) {
    texture = loadImage(name);
    //println("texture " + name);
  }
}

class MQOMaterial {
  String name;
  //byte shader;
  boolean vcol;
  int col;
  int dif, amb, emi, spc;
  float power;
  MQOTex tex;
  //MQOTex aplane;
  //MQOTex bump;
}

class MQOFace {
  int index[];
  float u[];
  float v[];
  byte materialIndex;
  byte num;
}

class MQOObject {
  String name;
  byte depth;
  //int folding;
  PVector scale;
  PVector rotation;
  PVector translation;
  //int patch;
  //int segment;
  boolean visible;
  //boolean locking;
  byte shading; // 0 \u30d5\u30e9\u30c3\u30c8\u30b7\u30a7\u30fc\u30c7\u30a3\u30f3\u30b0 1 \u30b0\u30ed\u30fc\u30b7\u30a7\u30fc\u30c7\u30a3\u30f3\u30b0
  float facet;
  int col;
  //byte color_type;
  //byte mirror;
  //byte mirror_axis;
  //float mirror_dis;
  //int lathe;
  //int lathe_axis;
  //int lathe_seg;
  PVector vertices[];
  PVector normals[];
  MQOFace faces[];

  public PVector getFaceNormal(int faceIndex) {
    MQOFace f = faces[faceIndex];
    PVector a = vertices[f.index[0]];
    PVector b = vertices[f.index[1]];
    PVector c = vertices[f.index[2]];
    PVector n = PVector.sub(a, b).cross(PVector.sub(c, b));
    n.normalize();
    return n;
  }
}

// MQO\u30e2\u30c7\u30eb\u30af\u30e9\u30b9
class MQOModel {
  private MQOMaterial materials[];
  private MQOMaterial defaultMaterial;
  private ArrayList<MQOObject> objects;

  private byte shadingMode;
  final static byte SHADING_FLAT = 0;          // \u30d5\u30e9\u30c3\u30c8\u30b7\u30a7\u30fc\u30c7\u30a3\u30f3\u30b0
  final static byte SHADING_GOURAUD = 1;       // \u30b0\u30ed\u30fc\u30b7\u30a7\u30fc\u30c7\u30a3\u30f3\u30b0
  final static byte SHADING_WIREFRAME = 2;     // \u30ef\u30a4\u30e4\u30fc\u30d5\u30ec\u30fc\u30e0(MQO\u306b\u306f\u306a\u3044)
  final static byte SHADING_AUTO = -1;         // \u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u306e\u8a2d\u5b9a\u5024\u3092\u4f7f\u7528

  private PImage envMap;                       // \u74b0\u5883\u30de\u30c3\u30d7\u7528\u30c6\u30af\u30b9\u30c1\u30e3
  private int envMapColor;                   // \u74b0\u5883\u30de\u30c3\u30d7\u8272
  private byte envMapMode;
  final static byte ENVMAP_NONE = 0;           // \u74b0\u5883\u30de\u30c3\u30d7\u306a\u3057
  final static byte ENVMAP_REFLECTION = 1;     // \u74b0\u5883\u53cd\u5c04\u30de\u30c3\u30d4\u30f3\u30b0(REFLECTION)
  final static byte ENVMAP_REFLECTION_ONLY = 2;// \u74b0\u5883\u53cd\u5c04\u30de\u30c3\u30d4\u30f3\u30b0\u306e\u307f\u3067\u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u63cf\u753b
  final static byte ENVMAP_GLASS = 3;          // \u74b0\u5883\u5c48\u6298\u30de\u30c3\u30d4\u30f3\u30b0(REFLACTION)
  final static byte ENVMAP_GLASS_REVERSE = 4;  // \u74b0\u5883\u5c48\u6298\u30de\u30c3\u30d4\u30f3\u30b0 UV\u53cd\u8ee2\u7248

  // \u30b3\u30f3\u30b9\u30c8\u30e9\u30af\u30bf\u3067\u8aad\u307f\u8fbc\u307f
  MQOModel(PApplet applet, String file) {
    String[] lines = loadStrings(file);
    
    int cur = parseMaterialChunk(lines, 0);
    if(cur<0) { cur = 0; }

    defaultMaterial = new MQOMaterial();
    defaultMaterial.name = "default";
    defaultMaterial.vcol = false;
    defaultMaterial.col = color(255);
    defaultMaterial.dif = blendColor(color(208), defaultMaterial.col, MULTIPLY);
    defaultMaterial.amb = blendColor(color(153), defaultMaterial.col, MULTIPLY);
    defaultMaterial.emi = blendColor(color(0), defaultMaterial.col, MULTIPLY);
    defaultMaterial.spc = blendColor(color(0), defaultMaterial.col, MULTIPLY);
    defaultMaterial.power = 9.0f;
    
    objects = new ArrayList<MQOObject>();
    while(cur>=0) {
      cur = parseObjectChunk(lines, cur);
    }
    
    computeNormals();
    sortFaces();
    shadingMode = SHADING_AUTO;
    envMap = null;
    envMapColor = color(0);
    envMapMode = ENVMAP_NONE;
  }

  // \u30b7\u30a7\u30fc\u30c7\u30a3\u30f3\u30b0\u30bf\u30a4\u30d7\u6307\u5b9a(SHADING_*\u304b\u3089)
  public void setShading(byte shading) {
    shadingMode = shading;
  }

  // \u74b0\u5883\u30de\u30c3\u30d7\u6307\u5b9a
  public void setEnvMap(byte envMapMode, PImage texture) {
    setEnvMap(envMapMode, texture, color(255));
  }
  public void setEnvMap(byte envMapMode, PImage texture, int envMapColor) {
    envMap = texture;
    this.envMapColor = envMapColor;
    this.envMapMode = envMapMode;
  }
  public void noEnvMap() {
    setEnvMap(ENVMAP_NONE, null, color(0));
  }

  // \u9802\u70b9\u3092\u307e\u3068\u3081\u305f\u3082\u306e\u3092\u8fd4\u3059
  public float[] getAllTriangleVertices() {
    if(objects==null) return null;

    int numOfVertices = 0;
    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      numOfVertices += o.vertices.length * 3; // 3 = x y z
    }
    if(numOfVertices<=0) return null;

    float[] allVertices = new float[numOfVertices];
    int cur = 0;

    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      PMatrix m = new PMatrix3D();
      m.translate(o.translation.x, o.translation.y, o.translation.z);
      m.scale(o.scale.x, o.scale.y, o.scale.z);
      m.rotateY(o.rotation.y); m.rotateX(o.rotation.x); m.rotateZ(o.rotation.z); // HPB\u56de\u8ee2
      
      PVector v = new PVector();
      for (int j=0; j<o.vertices.length; j++) {
        m.mult(o.vertices[j], v);
        //v = o.vertices[j];
        allVertices[cur++] = v.x;
        allVertices[cur++] = v.y;
        allVertices[cur++] = v.z;
      }
    }
    return allVertices;
  }

  // \u9802\u70b9\u30a4\u30f3\u30c7\u30c3\u30af\u30b9\u3092\u307e\u3068\u3081\u305f\u3082\u306e\u3092\u8fd4\u3059
  public int[] getAllTriangleIndices() {
    if(objects==null) return null;

    int numOfIndices = 0;
    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      for (int j=0; j<o.faces.length; j++) {
        MQOFace f = o.faces[j];
        if(f.num>=3) numOfIndices += 3; // 3 = triangle
        if(f.num>=4) numOfIndices += 3; // \u56db\u89d2\u5f62\u30dd\u30ea\u30b4\u30f3\u306f\u3082\u3046\uff11\u679aTriangle\u3092\u8db3\u3059
      }
    }
    if(numOfIndices<=0) return null;

    int[] allIndices = new int[numOfIndices];
    int cur = 0;
    int addIndex = 0;

    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      for (int j=0; j<o.faces.length; j++) {
        MQOFace f = o.faces[j];
        if(f.num>=3) {
          allIndices[cur++] = addIndex + f.index[0];
          allIndices[cur++] = addIndex + f.index[1];
          allIndices[cur++] = addIndex + f.index[2];
        }
        if(f.num>=4) {
          allIndices[cur++] = addIndex + f.index[2];
          allIndices[cur++] = addIndex + f.index[3];
          allIndices[cur++] = addIndex + f.index[0];
        }
      }
      addIndex += o.vertices.length;
    }
    return allIndices;
  }

  // \u63cf\u753b
  public void draw() {
    if(objects==null) return;

    pushStyle();

    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);

      // \u30ed\u30fc\u30ab\u30eb\u5ea7\u6a19\u306a\u3069\u3092\u8a2d\u5b9a
      pushMatrix();
      translate(o.translation.x, o.translation.y, o.translation.z);
      scale(o.scale.x, o.scale.y, o.scale.z);
      rotateY(o.rotation.y); rotateX(o.rotation.x); rotateZ(o.rotation.z); // HPB\u56de\u8ee2

      // \u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u63cf\u753b
      if( envMapMode!=ENVMAP_GLASS && envMapMode!=ENVMAP_GLASS_REVERSE && envMapMode!=ENVMAP_REFLECTION_ONLY ) {
        drawObject(o, ENVMAP_NONE);
      }
      if(envMapMode!=ENVMAP_NONE) {
        drawObject(o, envMapMode);
      }

      popMatrix();
    }

    popStyle();
  }

  // \u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u63cf\u753b
  private void drawObject(MQOObject o, byte envMapMode) {
    PMatrix3D matrix = new PMatrix3D();
    getMatrix(matrix);
    PVector cameraPos = new PVector(-matrix.m03, -matrix.m13, -matrix.m23);
    matrix.m03 = matrix.m13 = matrix.m23 = 0.0f; // 3x3\u3067\u3088\u3044

    // \u30b7\u30a7\u30fc\u30c7\u30a3\u30f3\u30b0\u30e2\u30fc\u30c9\u3092\u8a2d\u5b9a
    byte nowShading = (shadingMode==SHADING_AUTO) ? o.shading : shadingMode;
    if(nowShading==SHADING_WIREFRAME) noFill();
    else noStroke();
    
    // \u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u3092\u30d9\u30bf\u306b\u63cf\u753b
    int faceVNum = -1;
    int materialIndex = -1;
    PImage img = null;
    for (int j=0; j<o.faces.length; j++) {
      MQOFace f = o.faces[j];

      // \u30de\u30c6\u30ea\u30a2\u30eb\u306a\u3069\u306e\u8a2d\u5b9a
      if(f.materialIndex!=materialIndex || f.num!=faceVNum) {
        faceVNum = f.num;
        if(j!=0) endShape();
        if(f.num==3) beginShape(TRIANGLES);
        else beginShape(QUAD);

        img = null;
        materialIndex = f.materialIndex;
        MQOMaterial m = defaultMaterial;
        if(materialIndex>=0 && materialIndex<materials.length) {
          m = materials[materialIndex];
        }
        if(nowShading==SHADING_WIREFRAME) stroke(m.dif);
        else {
          if(envMapMode!=ENVMAP_NONE) {
            img = envMap;
            texture(img);
            textureMode(NORMAL);
            tint(envMapColor);
          } else if(m.tex!=null) {
            img = m.tex.texture;
            texture(img);
            textureMode(NORMAL);
            noTint();
          } else {
            //noTexture();
          }
          if(envMapMode==ENVMAP_GLASS || envMapMode==ENVMAP_GLASS_REVERSE) {
            fill(255);
          } else {
            fill(m.dif);
            ambient(m.amb);
            specular(m.spc);
            emissive(m.emi);
            shininess(m.power);
          }
        }
      }

      // \u30dd\u30ea\u30b4\u30f3\u63cf\u753b
      PVector uvn = new PVector();
      for (int k=0; k<f.num; k++) {
        PVector v = o.vertices[f.index[k]];
        PVector n = o.normals[f.index[k]];
        if(nowShading!=SHADING_FLAT) {
          normal( n.x, n.y, n.z );
        }
        float tu, tv;
        if(envMapMode==ENVMAP_NONE) {
          tu = f.u[k];
          tv = f.v[k];
        } else {
          if(envMapMode==ENVMAP_REFLECTION || envMapMode==ENVMAP_REFLECTION_ONLY) {
            // \u53cd\u5c04\u30de\u30c3\u30d4\u30f3\u30b0
            matrix.mult(n, uvn);
            uvn.normalize();
            uvn.x *= -1.0f;
            uvn.y *= -1.0f;
          } else {
            // \u5c48\u6298\u30de\u30c3\u30d4\u30f3\u30b0
            PVector lv = new PVector();
            matrix.mult(v, lv);
            PVector e = PVector.sub(cameraPos, lv);
            e.normalize();
            float factor = 0.15f;  // 0\uff5e2
            uvn = PVector.sub( PVector.mult(n, factor * e.dot(n)), e );
            //uvn.normalize();
            if(envMapMode==ENVMAP_GLASS_REVERSE) {
              uvn.x *= -1.0f;
              uvn.y *= -1.0f;
            }
          }
          tu = uvn.x * 0.5f + 0.5f;
          tv = uvn.y * 0.5f + 0.5f;
        }
        if(img!=null) {
          vertex( v.x, v.y, v.z, tu, tv );
        } else {
          vertex( v.x, v.y, v.z );
        }
      }
    }

    if(o.faces.length>0) endShape();
  }

  // \u30c1\u30e3\u30f3\u30af\u884c\u3092\u53d6\u5f97
  private int findChunkLine(String chunkName, String[] lines, int startLine) {
    for(int i=startLine; i < lines.length; i++) {
      if(lines[i].indexOf(chunkName)>=0) {
        //println(lines[i]);
        return i;
      }
    }
    return -1;
  }

  // \u6587\u5b57\u5217\u3092\u30d1\u30e9\u30e1\u30fc\u30bf\u306b\u5206\u5272
  private String[] splitArg(String str) {
    return splitTokens(str, " \t()\"{}");
  }

  // \u8a72\u5f53\u30d1\u30e9\u30e1\u30fc\u30bfindex\u3092\u53d6\u5f97
  private int findArg(String name, int valueNum, String[] args, int startArg) {
    for(int i=startArg; i<args.length; i++) {
      if(args[i].equalsIgnoreCase(name) && i+valueNum<args.length) {
      //if(args[i].compareToIgnoreCase(name)==0 && i+valueNum<args.length) {
        return i;
      }
    }
    return -1;
  }

  // \u5404\u7a2e\u30d1\u30e9\u30e1\u30fc\u30bf\u5024\u3092\u6307\u5b9a\u578b\u3067\u53d6\u5f97
  private boolean getBoolean(String name, String[] args, int startArg, boolean defaultVal) {
    return getInt(name, args, startArg, PApplet.parseInt(defaultVal))!=0;
  }

  private byte getByte(String name, String[] args, int startArg, int defaultVal) {
    return PApplet.parseByte(getInt(name, args, startArg, defaultVal));
  }

  private int getInt(String name, String[] args, int startArg, int defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return PApplet.parseInt(args[i+1]);
    } else return defaultVal;
  }

  private float getFloat(String name, String[] args, int startArg, float defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return PApplet.parseFloat(args[i+1]);
    } else return defaultVal;
  }

  private String getString(String name, String[] args, int startArg, String defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return args[i+1];
    } else return defaultVal;
  }

  private int getColor(String name, String[] args, int startArg, int defaultVal) {
    int i = findArg(name, 3, args, startArg);
    if(i>=0) {
      return color(PApplet.parseFloat(args[i+1])*255, PApplet.parseFloat(args[i+2])*255, PApplet.parseFloat(args[i+3])*255);
    } else return defaultVal;
  }

  private int getColorGray(String name, String[] args, int startArg, int defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return color(PApplet.parseFloat(args[i+1])*255);
    } else return defaultVal;
  }
  
  private PVector getVector(String name, String[] args, int startArg, PVector defaultVal) {
    int i = findArg(name, 3, args, startArg);
    if(i>=0) {
      return new PVector(PApplet.parseFloat(args[i+1]), PApplet.parseFloat(args[i+2]), PApplet.parseFloat(args[i+3]));
    } else return new PVector(defaultVal.x, defaultVal.y, defaultVal.z);
  }

  // \u30de\u30c6\u30ea\u30a2\u30eb\u306e\u8aad\u307f\u8fbc\u307f
  private int parseMaterialChunk(String[] lines, int startLine) {
    int cur = startLine;
    cur = findChunkLine("Material", lines, cur);
    if(cur < 0) return -1;

    String[] args = splitArg(lines[cur++]);
    if(args.length <= 1) return -1;
    int num = PApplet.parseInt(args[1]);
    if(num<=0) return -1;
    materials = new MQOMaterial[num];
    for(int i=0; i<num; i++) {
      args = splitArg(lines[cur++]);
      MQOMaterial m = new MQOMaterial();
      m.name = args[0];
      m.vcol = getBoolean("vcol", args, 1, false);
      m.col = getColor("col", args, 1, color(255));
      m.dif = blendColor(m.col, getColorGray("dif", args, 1, color(208)), MULTIPLY);
      m.amb = blendColor(m.col, getColorGray("amb", args, 1, color(153)), MULTIPLY);
      m.emi = blendColor(m.col, getColorGray("emi", args, 1, color(0)), MULTIPLY);
      m.spc = blendColor(m.col, getColorGray("spc", args, 1, color(0)), MULTIPLY);
      m.power = map( getFloat("power", args, 1, 0.0f), 0, 100, 0, 180 );
      String texName = getString("tex", args, 1, null);
      if(texName!=null) {
        m.tex = new MQOTex(texName);
      }
      materials[i] = m;
    }

    return cur;
  }

  // \u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u306e\u8aad\u307f\u8fbc\u307f
  private int parseObjectChunk(String[] lines, int startLine) {
    int cur = startLine;
    cur = findChunkLine("Object", lines, cur);
    if(cur < 0) return -1;

    String[] args = splitArg(lines[cur++]);
    //println(args);
    if(args.length <= 1) return -1;
    
    MQOObject o = new MQOObject();
    o.name = args[1];
    
    int vertexLine = findChunkLine("vertex", lines, cur);
    if(vertexLine < 0) return -1;

    // \u30d1\u30e9\u30e1\u30fc\u30bf
    String s = "";
    for (int i=cur; i<vertexLine; i++) {
      s += " " + lines[cur++];
    }
    args = splitArg(s);
    //println(args);

    PVector zeroV = new PVector(0, 0, 0);
    PVector oneV = new PVector(1, 1, 1);
    o.depth = getByte("depth", args, 0, 0);
    o.scale = getVector("scale", args, 0, oneV);
    PVector hpb = getVector("rotation", args, 0, zeroV);
    o.rotation = new PVector(hpb.y, hpb.x, hpb.z);
    o.translation = getVector("translation", args, 0, zeroV);
    o.visible = getInt("visible", args, 0, 15)!=0;
    o.shading = getByte("shading", args, 0, 1);
    o.facet = getFloat("facet", args, 0, 0);
    o.col = getColor("color", args, 0, color(255));
    
    // \u9802\u70b9
    args = splitArg(lines[cur++]);
    if(args.length <= 1) return -1;
    int num = PApplet.parseInt(args[1]);
    if(num<=0) return -1;
    
    o.vertices = new PVector[num];
    o.normals = new PVector[num];
    for(int i=0; i<num; i++) {
      args = splitArg(lines[cur++]);
      if(args.length<3) return -1;
      o.vertices[i] = new PVector(PApplet.parseFloat(args[0]), -PApplet.parseFloat(args[1]), PApplet.parseFloat(args[2]));
      o.normals[i] = new PVector(0, 0, 0);
    }

    // \u9762
    cur = findChunkLine("face", lines, cur);
    if(cur < 0) return -1;

    args = splitArg(lines[cur++]);
    if(args.length <= 1) return -1;
    num = PApplet.parseInt(args[1]);
    if(num<=0) return -1;

    o.faces = new MQOFace[num];
    for(int i=0; i<num; i++) {
      args = splitArg(lines[cur++]);
      if(args.length<1) return -1;

      MQOFace face = new MQOFace();
      face.num = PApplet.parseByte(PApplet.parseInt(args[0]));
      if(face.num<3 || face.num>4) return -1;

      face.index = new int[face.num];
      face.u = new float[face.num];
      face.v = new float[face.num];

      int c = findArg("V", face.num, args, 1);
      if(c<0) return -1;
      for(int j=0; j<face.num; j++) face.index[j] = PApplet.parseInt(args[c+1+j]);

      face.materialIndex = getByte("M", args, 1, -1);

      c = findArg("UV", face.num*2, args, 1);
      if(c>=0) {
        for(int j=0; j<face.num; j++) {
          face.u[j] = PApplet.parseFloat(args[c+1+j*2]);
          face.v[j] = PApplet.parseFloat(args[c+2+j*2]);
        }
      }
      o.faces[i] = face;
    }

    objects.add(o);
    return cur;
  }

  // \u9802\u70b9\u6cd5\u7dda\u8a08\u7b97
  private void computeNormals() {
    if(objects==null) return;

    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      if(!o.visible) continue;

      // \u9802\u70b9\u6cd5\u7dda\u8a08\u7b97
      for (int j=0; j<o.normals.length; j++) {
        o.normals[j].set(0, 0, 0);
      }
      for (int j=0; j<o.faces.length; j++) {
        MQOFace f = o.faces[j];
        PVector fn = o.getFaceNormal(j);
        o.normals[f.index[0]].add(fn);
        o.normals[f.index[1]].add(fn);
        o.normals[f.index[2]].add(fn);
        if(f.num==4) {
          //o.normals[f.index[0]].add(fn);
          //o.normals[f.index[2]].add(fn);
          o.normals[f.index[3]].add(fn);
        }
      }
      for (int j=0; j<o.normals.length; j++) {
        o.normals[j].normalize();
      }

      // \u30b9\u30e0\u30fc\u30b8\u30f3\u30b0\u89d2\u3092\u898b\u3066\u9802\u70b9\u6cd5\u7dda\u3092\u4fee\u6b63
      for (int j=0; j<o.faces.length; j++) {
        MQOFace f = o.faces[j];
        PVector fn = o.getFaceNormal(j);
        for (int k=0; k<f.num; k++) {
          PVector vn = o.normals[f.index[k]];
          float facet = degrees( acos(PVector.dot(fn, vn)) );
          if(facet > o.facet) {
            o.normals[f.index[k]].set(fn); // \u9762\u6cd5\u7dda\u3092\u4f7f\u3063\u3066\u30a8\u30c3\u30b8\u3092\u92ed\u304f
          }
        }
      }
    }
  }

  // \u9762\u3092\u30bd\u30fc\u30c8
  private void sortFaces() {
    if(objects==null) return;

    // \u30de\u30c6\u30ea\u30a2\u30eb\u9806\u3001\u9762\u306e\u9802\u70b9\u6570\u9806\u3067\u30bd\u30fc\u30c8\u7528\u306e\u6bd4\u8f03\u3092\u884c\u3046\u30af\u30e9\u30b9
    class MQOFaceComparator implements Comparator<MQOFace> {
       public int compare(MQOFace f1, MQOFace f2){
         if(f1.materialIndex!=f2.materialIndex) {
           return f1.materialIndex < f2.materialIndex ? -1 : 1;
         } else {
           return f1.num < f2.num ? -1 : 1;
         }
       }
    }
    MQOFaceComparator faceComparator = new MQOFaceComparator();

    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      Arrays.sort(o.faces, faceComparator);
    }
  }
}
//----------------------------------------------
// 3D\u7a7a\u9593\u306b\u914d\u7f6e\u3059\u308b\u57fa\u672c\u30e6\u30cb\u30c3\u30c8\u30af\u30e9\u30b9
class Unit {
  PMatrix3D matrix = new PMatrix3D();  // \u884c\u5217(\u59ff\u52e2\u3068\u4f4d\u7f6e)
  PVector pos = new PVector();         // \u4f4d\u7f6e(\u6700\u7d42\u7684\u306b\u306fmatrix\u306b\u53cd\u6620\u3055\u305b\u308b)
  PVector vel = new PVector();         // \u901f\u5ea6
  float radius;                        // \u534a\u5f84
  float life;                          // \u4f53\u529b(100\uff5e)
  int group;                           // \u30b0\u30eb\u30fc\u30d7ID

  // \u30b3\u30f3\u30b9\u30c8\u30e9\u30af\u30bf
  Unit(float x, float y, float z, float radius, int group) {
    pos.x = x; pos.y = y; pos.z = z;
    this.radius = radius; life = 100.0f; this.group = group;
  }

  // \u52a0\u901f
  public void accel(float speed) {
    vel.x += matrix.m02 * -speed;  vel.y += matrix.m12 * -speed;  vel.z += matrix.m22 * -speed;
  }

  // \u505c\u6b62
  public void stop() {
    vel.set(0, 0, 0);
  }

  // \u56de\u8ee2
  public void rotate(float rotX, float rotY, float rotZ) {
    matrix.rotateY(radians(rotY));  matrix.rotateX(radians(rotX));  matrix.rotateZ(radians(rotZ));
  }

  // \u6307\u5b9a\u306e\u4f4d\u7f6e\u306e\u65b9\u3092\u5411\u304f
  public void lookAtPos(PVector targetPos) {
    PVector dir = PVector.sub(targetPos, pos);
    dir.normalize();
    lookAtDir(dir);
  }

  // \u59ff\u52e2(Z\u8ef8)\u3092\u6307\u5b9a\u306e\u5411\u304d\u306b\u3059\u308b
  public void lookAtDir(PVector direction) {
    PVector vz = PVector.mult(direction, -1); vz.normalize();
    PVector vx = vz.cross(new PVector(0,-1,0)); vx.normalize();
    PVector vy = vz.cross(vx); vy.normalize();
    matrix.set(vx.x, vy.x, vz.x, pos.x, vx.y, vy.y, vz.y, pos.y, vx.z, vy.z, vz.z, pos.z, 0, 0, 0, 1);
  }
  
  // \u524d\u5411\u304d\u306e\u30d9\u30af\u30c8\u30eb\u3092\u8fd4\u3059
  public PVector getForward() {
    return new PVector(-matrix.m02, -matrix.m12, -matrix.m22);
  }

  // \u53f3\u5411\u304d\u306e\u30d9\u30af\u30c8\u30eb\u3092\u8fd4\u3059
  public PVector getRight() {
    return new PVector(matrix.m00, matrix.m10, matrix.m20);
  }

  // \u4e0a\u5411\u304d\u306e\u30d9\u30af\u30c8\u30eb\u3092\u8fd4\u3059
  public PVector getUp() {
    return new PVector(matrix.m01, matrix.m11, matrix.m21);
  }

  // 1\u30d5\u30ec\u30fc\u30e0\u5206\u306e\u9032\u884c
  public void update() {
    pos.x += vel.x; pos.y += vel.y; pos.z += vel.z;
  }

  // \u884c\u5217\u306b\u73fe\u5728\u306epos\u3092\u53cd\u6620\u3055\u305b\u308b
  public void updateMatrix() {
    matrix.m03 = pos.x; matrix.m13 = pos.y; matrix.m23 = pos.z;
  }

  // \u63cf\u753b
  public void draw() {
    pushMatrix();
      updateMatrix();      // \u4f4d\u7f6e\u3092\u884c\u5217\u306b\u53cd\u6620
      applyMatrix(matrix); // \u884c\u5217\uff08\u4f4d\u7f6e\u3068\u59ff\u52e2\uff09\u3092\u6307\u5b9a
      drawShape();         // \u5f62\u72b6\u306e\u63cf\u753b
    popMatrix();
  }

  // \u5f62\u72b6\u306e\u63cf\u753b
  public void drawShape() {
    fill(255); box(radius);
  }

  // \u885d\u7a81\u5224\u5b9a
  // (\u4ed6\u306e\u30b0\u30eb\u30fc\u30d7\u306e\u30e6\u30cb\u30c3\u30c8\u3068\u91cd\u306a\u3063\u3066\u3044\u308b\u5834\u5408\u306ftrue\u3092\u8fd4\u3059)
  public boolean isHit(Unit unit) {
    if(group==unit.group) return false;
    else return pos.dist(unit.pos) <= radius + unit.radius;
  }

  // \u30c0\u30e1\u30fc\u30b8\u3092\u4e0e\u3048\u308b(life\u3092\u6e1b\u3089\u3059)
  public boolean damage(float damage) {
    life -= damage;
    return life<=0.0f;
  }
}

//----------------------------------------------
// \u6226\u95d8\u6a5f\u30af\u30e9\u30b9
class Fighter extends Unit  {
  Fighter(float x, float y, float z, float radius, int group) {
    super(x, y, z, radius, group);
  }

  // \u5f3e\u3092\u767a\u5c04
  public Bullet shoot(int power, float radian) {
    Bullet bullet = new Bullet(pos.x, pos.y, pos.z, 7, group, power);
    bullet.matrix.set(matrix);
    PVector randomVec = PVector.mult(PVector.random3D(), radian);
    if(radian>0) bullet.rotate(randomVec.x, randomVec.y, randomVec.z);  // \u5c11\u3057\u5411\u304d\u3092\u30e9\u30f3\u30c0\u30e0\u306b\u3070\u3089\u3051\u3055\u305b\u308b
    bullet.accel(70);
    bulletList.add(bullet);
    return bullet;
  }
}

//----------------------------------------------
// \u30d7\u30ec\u30a4\u30e4\u30fc\u6226\u95d8\u6a5f\u30af\u30e9\u30b9
class Player extends Fighter {
  Player(float x, float y, float z, float radius) {
    super(x, y, z, radius, PLAYER);
  }

  // \u5f62\u72b6\u306e\u63cf\u753b
  public void drawShape() {
    stroke(0, 255, 0, 64); strokeWeight(2); noFill();
    translate(0, 0, -10);
    box(radius, radius, radius*5);
    noStroke();
  }
}

//----------------------------------------------
// \u6575\u6226\u95d8\u6a5f\u30af\u30e9\u30b9
class Enemy extends Fighter {
  MQOModel model;  // \u30e2\u30c7\u30eb
  int level;       // \u6575\u306e\u601d\u8003\u30ec\u30d9\u30eb(0\uff5e2)
  int frame;       // frameCount

  Enemy(MQOModel model, float x, float y, float z, float radius) {
    super(x, y, z, radius, ENEMY); 
    this.model = model;
    level = PApplet.parseInt(random(3));
    frame = 0;
  }

  // \u9032\u884c
  public void update() {
    // \u30d7\u30ec\u30a4\u30e4\u30fc\u306e\u65b9\u306b\u5411\u3044\u3066\u79fb\u52d5
    PVector dir = PVector.sub(player.pos, pos);
    dir.normalize();
    PVector forward = getForward();
    float lerpLevel = 0.05f * (1 + level);
    forward.lerp(dir, lerpLevel);
    lookAtDir(forward);
    accel(0.01f * level);
    super.update();
    // \u30b2\u30fc\u30e0\u958b\u59cb\u5f8c\u3001\u4e00\u5b9a\u79d2\u7d4c\u904e\u3057\u305f\u3042\u3068\u3001\u305f\u307e\u306b\u5f3e\u767a\u5c04
    frame++;
    if( frame > 180 * (1+level) && 0==(frame % (80-level*20)) ) {
      shoot(10, radians(10 + 10*level));
    }
  }

  // \u5f62\u72b6\u306e\u63cf\u753b
  public void drawShape() {
    model.draw();
  }
}

//----------------------------------------------
// \u5f3e\u30af\u30e9\u30b9
class Bullet extends Unit  {
  int power;  // \u5a01\u529b

  Bullet(float _x, float _y, float _z, float _radius, int _group, int _power) {
    super(_x, _y, _z, _radius, _group);
    power = _power;
  }

  // \u5f62\u72b6\u306e\u63cf\u753b
  public void drawShape() {
    damage(0.5f);
    if(group==PLAYER) stroke(0, 128, 255, 128);
    else stroke(255, 0, 0, 128);
    strokeWeight(4 * screenScale); fill(255);
    translate(0, radius*7, 0);
    box(radius, radius, radius*20);
  }
}

//----------------------------------------------
// \u30a8\u30d5\u30a7\u30af\u30c8\u30af\u30e9\u30b9
class Effect extends Unit  {
  Effect(float x, float y, float z, float radius) {
    super(x, y, z, radius, EFFECT);
  }

  // \u5f62\u72b6\u306e\u63cf\u753b
  public void drawShape() {
    damage(2);

    lookAtPos(player.pos); // \u30d7\u30ec\u30a4\u30e4\u30fc\u306e\u65b9\u3092\u5411\u304f\u3053\u3068\u3067\u30d3\u30eb\u30dc\u30fc\u30c9\u306b\u3059\u308b
    float alpha = norm(life, 0, 100);
    tint(255, 255 * alpha);
    float s = 5000 * (1.0f - alpha);
    imageMode(CENTER);
    image(explosionImg, 0, 0, s, s);
    tint(255);
  }
}
  public void settings() {  fullScreen(P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "ShootingStarP3" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
