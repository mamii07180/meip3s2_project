// ShootingStarP3 (c)2015 NISHIDA Ryota - http://dev.eyln.com (zlib License)

// 戦闘機リスト（プレイヤー含む）、弾リスト、エフェクトリスト
ArrayList<Fighter> fighterList = new ArrayList<Fighter>();
ArrayList<Bullet> bulletList = new ArrayList<Bullet>();
ArrayList<Effect> effectList = new ArrayList<Effect>();

// グループ分類用の定数
final int PLAYER = 0;
final int ENEMY = 1;
final int EFFECT = 2; 

Player player;              // プレイヤー戦闘機(自機)
MQOModel enemyModel;        // 敵モデル
MQOModel planetModel;       // 惑星モデル
PImage earthImg;
PImage explosionImg;
float cameraShake = 0.0;    // 現在のカメラの揺れ具合
int clearTime = 0;          // クリアタイム

int framePrevTime = 0;      // 前フレームの時間
float frameStepBase = 1;    // 1フレームで進む量の計算用
int frameStep = 1;          // 1フレームで進む量

float screenScale = 1.0f;   // 画面拡大率
int baseWidth = 640;        // 基準画面の横幅
int baseHeight = 480;       // 基準画面の縦幅

// Android環境の場合trueを返す
boolean isAndroid() {
  return System.getProperty("java.vendor").equalsIgnoreCase("The Android Project");
}

//----------------------------------------------
// 初期化
void setup() {
  //size(640, 480, P3D);
  //size(800, 600, P3D);
  fullScreen(P3D);

  if(isAndroid()) {
    orientation(LANDSCAPE);
  }

  screenScale = min(width / (float)baseWidth, height / (float)baseHeight);
  textFont( createFont("Lucida Console", 20) );

  // モデルの読み込み
  enemyModel = new MQOModel(this, "enemy.mqo");
  enemyModel.setShading(MQOModel.SHADING_FLAT);
  
  earthImg = loadImage("earth.jpg");
  explosionImg = loadImage("explosion.png");

  resetStage();  // ステージの初期化
  framePrevTime = millis();
}

//----------------------------------------------
// ステージの初期化
void resetStage() {
  // ユニットをすべて破棄
  fighterList.clear();
  effectList.clear();
  bulletList.clear();

  // 戦闘機の登録
  fighterList.add(player = new Player(0, 0, 100, 10));
  player.lookAtPos(new PVector(-200, 0, 0.0f));
  for(int i=0; i<10; i++) {
    PVector pos = new PVector(random(-5000, -4000), random(-2000, 2000), random(-2000, 20000));
    fighterList.add(new Enemy(enemyModel, pos.x, pos.y, pos.z, 150));
  }

  clearTime = 0;
}

//----------------------------------------------
// 描画
void draw(){
  // ユニット進行
  updateFrameStep();
  for(int i=0; i<frameStep; i++) {
    update();
  }
  
  // 宇宙背景の描画
  background(0);
  scale(screenScale);
  noLights();
  setUnitCamera(player);
  drawStars();
  setLights();

  // プレイヤーと敵の描画
  for(Fighter fighter : fighterList) {
    fighter.draw();
  }

  // エフェクトの描画
  hint(DISABLE_DEPTH_TEST);
  blendMode(ADD);
  noLights();
  for(Effect effect : effectList) {
    effect.draw();
  }

  // 弾の描画
  for(Bullet bullet : bulletList) {
    bullet.draw();
  }
  blendMode(BLEND);

  // 情報表示
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
// プロジェクター投影先の色味と形状にあわせて画面を加工
void drawFilter() {
  /*
  // 緑色成分を減らす
  blendMode(MULTIPLY);
  fill(255, 180, 255, 255);
  rect(0, 0, width, height);
  blendMode(BLEND);
  */

  // 丸く縁取ってまわりを暗くする
  noFill();
  stroke(0);
  strokeWeight(height/2);
  ellipse(width/2, height/2, height*2.0f, height*1.8f); 
}

//----------------------------------------------
// 実際に進めるフレーム数を計算
// frameRateが60より小さくなっても進行速度が一定になるように
// frameStepを計算する(frameRateが30のときframeStepは2)
void updateFrameStep() {
  int nowTime = millis();
  frameStepBase += (nowTime - framePrevTime) / (1000 / 60.0f);  // 実際何フレーム分の時間が経過したか計算してベースに加算
  frameStep = int(frameStepBase);  // 今回進めるフレーム数を整数で設定
  frameStepBase -= frameStep;      // 今回進める分はベースから取り除く(小数点以下のみ残る)
  framePrevTime = nowTime;
}

//----------------------------------------------
// 進行
void update() {
  // プレイヤーと敵
  for(Fighter fighter : fighterList) {
    fighter.update();
  }

  // エフェクト
  for (int i=0;i<effectList.size();i++) {
    Effect effect = effectList.get(i);
    effect.update();
    if(effect.life<=0) effectList.remove(i--); // 寿命で消滅
  }

  // 弾
  for (int i=0;i<bulletList.size();i++) {
    Bullet bullet = bulletList.get(i);
    bullet.update();
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

  inputUnit(player);
  cameraShake *= 0.95;
}

///----------------------------------------------
// 情報表示
void drawInfo() {
  textSize(20);
  textAlign(CENTER, CENTER);
  int centerX = int(width / screenScale) / 2;
  int centerY = int(height / screenScale) / 2;

  // コクピット用丸フレーム
  noFill();
  stroke(220);
  strokeWeight(3);
  ellipse(centerX, centerY, baseHeight*0.4f, baseHeight*0.4f); 
  strokeWeight(10);
  ellipse(centerX, centerY*1.1f, baseHeight*0.88f, baseHeight*0.88f); 

  // ライフなど
  if(player.life > 30) fill(0, 255, 0, 255);  // 生きてるときは緑
  else fill(255, 0, 0, 255);                  // 死んでるときは赤

  if(player.life>0) {
    int enemyNum = fighterList.size()-1;
    if(enemyNum==0) {  // 敵の数が0のときはクリア画面
      clearDepth();
      textSize(40);
      text("MISSION CLEAR", centerX, baseHeight / 2 - 40);
      if(clearTime==0) clearTime = millis();
      text("TIME "+ nf(clearTime * 0.001f, 1, 1) + "sec", centerX, baseHeight/2 + 30 );
    } else {           // 通常は残りの敵の数を表示
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
    // 再プレイボタンを下部に表示
    noStroke();
    rect(0, height / screenScale - 60, width / screenScale, 60);
    fill(0);
    textSize(20);
    text("RETRY", centerX, height / screenScale - 30);
  }
}

//----------------------------------------------
// 毎フレームの入力
void inputUnit(Unit unit) {
  if(mouseX > 0 && mouseX < width && mouseY > 0 && mouseY < height) {
    // 回転
    float rotYLevel = map(mouseX, 0, width, -1, 1);
    float rotXLevel = map(mouseY, 0, height, -1, 1);
    unit.rotate(rotXLevel * abs(rotXLevel) * 3.0, -rotYLevel * abs(rotYLevel) * 3.0f, 0.0f);
  }
  if(player.life > 0) {
    if((keyPressed && key==' ') || mousePressed) unit.accel(0.04f); // 加速
    else unit.vel.mult(0.98f);  // 徐々に減速
  }
}

//----------------------------------------------
// マウスボタンを押した瞬間
void mousePressed() {
  if(player.life > 0) player.shoot(30, 1);
}

//----------------------------------------------
// マウスボタンを離した瞬間
void mouseReleased() {
  if(clearTime != 0 && mouseY > height - 60 * screenScale) resetStage();
}

//----------------------------------------------
// 爆発エフェクトを追加
void addExplosionEffect(Unit unit) {
  for(int i=0; i<3; i++) {
    Effect effect = new Effect(unit.pos.x, unit.pos.y, unit.pos.z, unit.radius);
    effect.vel.set(PVector.mult(PVector.random3D(), 10.0f));
    effectList.add(effect);
  }
}

//----------------------------------------------
// ユニット視点のカメラ
void setUnitCamera(Unit unit) {
  unit.updateMatrix();
  PVector sp = PVector.mult(PVector.random3D(), cameraShake * 0.01f); // カメラ揺らし用のベクトル
  PVector vz = unit.getForward();
  PVector vy = unit.getUp();
  float backLevel = unit.radius * -0.1f; // 一人称視点に近い位置にする
  camera(unit.pos.x + vz.x * backLevel, unit.pos.y + vz.y * backLevel, unit.pos.z + vz.z * backLevel, // 位置
         unit.pos.x + sp.x, unit.pos.y + sp.y, unit.pos.z + sp.z, // 注視点
         vy.x, vy.y, vy.z); // アップベクトル
  perspective(radians(60), float(width)/height, 5.0f, 10000.0f); // 画角と遠近の描画範囲を設定
}

//----------------------------------------------
// ライト設定
void setLights() {
  ambientLight(50, 50, 70); 
  directionalLight(255, 255, 255, 0, 1, 0); 
}

//----------------------------------------------
// 宇宙背景の描画
void drawStars() {
  pushMatrix();
  translate(player.pos.x, player.pos.y, player.pos.z);

  int seed = int(random(1000)); randomSeed(0);
  float range = 500.0;
  PVector starPos = new PVector();
  for(int i=0; i<150; i++) {
    // 遠くの星々
    strokeWeight(int(random(1,3) * screenScale)); stroke(random(128,255));
    starPos.set(random(-100, 100), random(-100, 100), random(-100, 100));
    point(starPos.x, starPos.y, starPos.z);

    // 近くの塵（プレイヤーのまわりに常にあるようにループさせる）
    starPos.set(random(range), random(range), random(range));
    starPos.x = modulo(-player.pos.x + starPos.x, range) - range * 0.5;
    starPos.y = modulo(-player.pos.y + starPos.y, range) - range * 0.5;
    starPos.z = modulo(-player.pos.z + starPos.z, range) - range * 0.5;
    line(starPos.x, starPos.y, starPos.z,
      starPos.x - player.vel.x * (range * 0.001) + 0.001f,
      starPos.y - player.vel.y * (range * 0.001),
      starPos.z - player.vel.z * (range * 0.001));
  }
  randomSeed(seed);

  // 惑星
  noStroke();
  translate(0,0,-300);
  imageMode(CENTER);
  image(earthImg, 0, 0, 1000, 1000);

  popMatrix();

  // 深度バッファをクリアして上に描画できるようにする
  clearDepth();
}

//----------------------------------------------
// 深度バッファをクリアする
void clearDepth() {
  PGraphicsOpenGL pgl = (PGraphicsOpenGL)g;
  PGL gl = pgl.beginPGL();
  gl.clear(PGL.DEPTH_BUFFER_BIT);
  pgl.endPGL();
}

//----------------------------------------------
// aをbで割った余りを返す
float modulo(float a, float b) {
  return a - floor(a / b) * b;
}