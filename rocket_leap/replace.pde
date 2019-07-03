void replace() {
      hp = 1000;
      hit = 0;
      ene_number = 0;
      enecount = 0;
      enecountb = 0;
      for (Enemy enemy : enemies){ //まず全ての敵を消去
        enemy.isDead = true;
        client.write(4 + " " + enemy.number + " " + 0 + "\n"); //死滅個体
      }
      for (int i = 0; i < 15; i++) { //最初に敵を15体作っておく
        ene_number=i;
          float ene_x, ene_y, ene_r;
          while (true) {
            ene_x = random(width);
            ene_y = random(height);
            ene_r = (15+random(30))*2;
            if (abs(w2 - ene_x) > 40 + ene_r && abs(height - 30 - ene_y) > 40 + ene_r) break;
          }
          enemies.add(new Enemy(ene_x, ene_y, ene_r, ene_number, 0));
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
}