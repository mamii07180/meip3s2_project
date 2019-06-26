//----------------------------------------------
// 3D空間に配置する基本ユニットクラス
class Unit {
  PMatrix3D matrix = new PMatrix3D();  // 行列(姿勢と位置)
  PVector pos = new PVector();         // 位置(最終的にはmatrixに反映させる)
  PVector vel = new PVector();         // 速度
  float radius;                        // 半径
  float life;                          // 体力(100～)
  int group;                           // グループID

  // コンストラクタ
  Unit(float x, float y, float z, float radius, int group) {
    pos.x = x; pos.y = y; pos.z = z;
    this.radius = radius; life = 100.0; this.group = group;
  }

  // 加速
  void accel(float speed) {
    vel.x += matrix.m02 * -speed;  vel.y += matrix.m12 * -speed;  vel.z += matrix.m22 * -speed;
  }

  // 停止
  void stop() {
    vel.set(0, 0, 0);
  }

  // 回転
  void rotate(float rotX, float rotY, float rotZ) {
    matrix.rotateY(radians(rotY));  matrix.rotateX(radians(rotX));  matrix.rotateZ(radians(rotZ));
  }

  // 指定の位置の方を向く
  void lookAtPos(PVector targetPos) {
    PVector dir = PVector.sub(targetPos, pos);
    dir.normalize();
    lookAtDir(dir);
  }

  // 姿勢(Z軸)を指定の向きにする
  void lookAtDir(PVector direction) {
    PVector vz = PVector.mult(direction, -1); vz.normalize();
    PVector vx = vz.cross(new PVector(0,-1,0)); vx.normalize();
    PVector vy = vz.cross(vx); vy.normalize();
    matrix.set(vx.x, vy.x, vz.x, pos.x, vx.y, vy.y, vz.y, pos.y, vx.z, vy.z, vz.z, pos.z, 0, 0, 0, 1);
  }
  
  // 前向きのベクトルを返す
  PVector getForward() {
    return new PVector(-matrix.m02, -matrix.m12, -matrix.m22);
  }

  // 右向きのベクトルを返す
  PVector getRight() {
    return new PVector(matrix.m00, matrix.m10, matrix.m20);
  }

  // 上向きのベクトルを返す
  PVector getUp() {
    return new PVector(matrix.m01, matrix.m11, matrix.m21);
  }

  // 1フレーム分の進行
  void update() {
    pos.x += vel.x; pos.y += vel.y; pos.z += vel.z;
  }

  // 行列に現在のposを反映させる
  void updateMatrix() {
    matrix.m03 = pos.x; matrix.m13 = pos.y; matrix.m23 = pos.z;
  }

  // 描画
  void draw() {
    pushMatrix();
      updateMatrix();      // 位置を行列に反映
      applyMatrix(matrix); // 行列（位置と姿勢）を指定
      drawShape();         // 形状の描画
    popMatrix();
  }

  // 形状の描画
  void drawShape() {
    fill(255); box(radius);
  }

  // 衝突判定
  // (他のグループのユニットと重なっている場合はtrueを返す)
  boolean isHit(Unit unit) {
    if(group==unit.group) return false;
    else return pos.dist(unit.pos) <= radius + unit.radius;
  }

  // ダメージを与える(lifeを減らす)
  boolean damage(float damage) {
    life -= damage;
    return life<=0.0;
  }
}

//----------------------------------------------
// 戦闘機クラス
class Fighter extends Unit  {
  Fighter(float x, float y, float z, float radius, int group) {
    super(x, y, z, radius, group);
  }

  // 弾を発射
  Bullet shoot(int power, float radian) {
    Bullet bullet = new Bullet(pos.x, pos.y, pos.z, 7, group, power);
    bullet.matrix.set(matrix);
    PVector randomVec = PVector.mult(PVector.random3D(), radian);
    if(radian>0) bullet.rotate(randomVec.x, randomVec.y, randomVec.z);  // 少し向きをランダムにばらけさせる
    bullet.accel(70);
    bulletList.add(bullet);
    return bullet;
  }
}

//----------------------------------------------
// プレイヤー戦闘機クラス
class Player extends Fighter {
  Player(float x, float y, float z, float radius) {
    super(x, y, z, radius, PLAYER);
  }

  // 形状の描画
  void drawShape() {
    stroke(0, 255, 0, 64); strokeWeight(2); noFill();
    translate(0, 0, -10);
    box(radius, radius, radius*5);
    noStroke();
  }
}

//----------------------------------------------
// 敵戦闘機クラス
class Enemy extends Fighter {
  MQOModel model;  // モデル
  int level;       // 敵の思考レベル(0～2)
  int frame;       // frameCount

  Enemy(MQOModel model, float x, float y, float z, float radius) {
    super(x, y, z, radius, ENEMY); 
    this.model = model;
    level = int(random(3));
    frame = 0;
  }

  // 進行
  void update() {
    // プレイヤーの方に向いて移動
    PVector dir = PVector.sub(player.pos, pos);
    dir.normalize();
    PVector forward = getForward();
    float lerpLevel = 0.05f * (1 + level);
    forward.lerp(dir, lerpLevel);
    lookAtDir(forward);
    accel(0.01 * level);
    super.update();
    // ゲーム開始後、一定秒経過したあと、たまに弾発射
    frame++;
    if( frame > 180 * (1+level) && 0==(frame % (80-level*20)) ) {
      shoot(10, radians(10 + 10*level));
    }
  }

  // 形状の描画
  void drawShape() {
    model.draw();
  }
}

//----------------------------------------------
// 弾クラス
class Bullet extends Unit  {
  int power;  // 威力

  Bullet(float _x, float _y, float _z, float _radius, int _group, int _power) {
    super(_x, _y, _z, _radius, _group);
    power = _power;
  }

  // 形状の描画
  void drawShape() {
    damage(0.5);
    if(group==PLAYER) stroke(0, 128, 255, 128);
    else stroke(255, 0, 0, 128);
    strokeWeight(4 * screenScale); fill(255);
    translate(0, radius*7, 0);
    box(radius, radius, radius*20);
  }
}

//----------------------------------------------
// エフェクトクラス
class Effect extends Unit  {
  Effect(float x, float y, float z, float radius) {
    super(x, y, z, radius, EFFECT);
  }

  // 形状の描画
  void drawShape() {
    damage(2);

    lookAtPos(player.pos); // プレイヤーの方を向くことでビルボードにする
    float alpha = norm(life, 0, 100);
    tint(255, 255 * alpha);
    float s = 5000 * (1.0f - alpha);
    imageMode(CENTER);
    image(explosionImg, 0, 0, s, s);
    tint(255);
  }
}