/*
 * Const.java
 *
 * ゲーム定数保持専用クラス.
 */

public class Const {
  public static final int CHIP = 100;//setEffect()メソッドでChipサイズを指定しなかった場合のデフォルトサイズ.
  public static final int IMAGE_EXPLODE = 0;
  public static final int IMAGE_SLASH = 1;
  public static final int IMAGE_MAGIC = 2;

  public static final String EFFECT_NAMES[] = {
    "explode", "slashred", "magic"
  };
  public static final int ATLAS_COLUMNS[] = { //エフェクトの元画像の列数.
    8, 9, 10
  };
  public static final int ATLAS_ROWS[] = { //エフェクトの元画像の行数.
    2, 1, 1
  };
  public static final int FRAME_LIMITS[] = { //エフェクトの元画像のフレーム数.
    15, 9, 10
  };
  public static final int EFFECT_CHIPS[] = { //エフェクトの元画像の１マス分のピクセル数.
    96, 120, 240
  };
}

