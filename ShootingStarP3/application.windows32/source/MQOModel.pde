/*******************************************************************************
 * MQO Loader - loads, displays, MQO models for Processing
 *  ver.0.2.3 - by NISHIDA Ryota (http://dev.eyln.com/)
 *
 * MQO FileFormat
 * http://www.metaseq.net/metaseq/format.html
 ********************************************************************************/

import java.util.Comparator;
import java.util.Arrays;

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
  color col;
  color dif, amb, emi, spc;
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
  byte shading; // 0 フラットシェーディング 1 グローシェーディング
  float facet;
  color col;
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

  PVector getFaceNormal(int faceIndex) {
    MQOFace f = faces[faceIndex];
    PVector a = vertices[f.index[0]];
    PVector b = vertices[f.index[1]];
    PVector c = vertices[f.index[2]];
    PVector n = PVector.sub(a, b).cross(PVector.sub(c, b));
    n.normalize();
    return n;
  }
}

// MQOモデルクラス
class MQOModel {
  private MQOMaterial materials[];
  private MQOMaterial defaultMaterial;
  private ArrayList<MQOObject> objects;

  private byte shadingMode;
  final static byte SHADING_FLAT = 0;          // フラットシェーディング
  final static byte SHADING_GOURAUD = 1;       // グローシェーディング
  final static byte SHADING_WIREFRAME = 2;     // ワイヤーフレーム(MQOにはない)
  final static byte SHADING_AUTO = -1;         // オブジェクトの設定値を使用

  private PImage envMap;                       // 環境マップ用テクスチャ
  private color envMapColor;                   // 環境マップ色
  private byte envMapMode;
  final static byte ENVMAP_NONE = 0;           // 環境マップなし
  final static byte ENVMAP_REFLECTION = 1;     // 環境反射マッピング(REFLECTION)
  final static byte ENVMAP_REFLECTION_ONLY = 2;// 環境反射マッピングのみでオブジェクト描画
  final static byte ENVMAP_GLASS = 3;          // 環境屈折マッピング(REFLACTION)
  final static byte ENVMAP_GLASS_REVERSE = 4;  // 環境屈折マッピング UV反転版

  // コンストラクタで読み込み
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

  // シェーディングタイプ指定(SHADING_*から)
  void setShading(byte shading) {
    shadingMode = shading;
  }

  // 環境マップ指定
  void setEnvMap(byte envMapMode, PImage texture) {
    setEnvMap(envMapMode, texture, color(255));
  }
  void setEnvMap(byte envMapMode, PImage texture, color envMapColor) {
    envMap = texture;
    this.envMapColor = envMapColor;
    this.envMapMode = envMapMode;
  }
  void noEnvMap() {
    setEnvMap(ENVMAP_NONE, null, color(0));
  }

  // 頂点をまとめたものを返す
  float[] getAllTriangleVertices() {
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
      m.rotateY(o.rotation.y); m.rotateX(o.rotation.x); m.rotateZ(o.rotation.z); // HPB回転
      
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

  // 頂点インデックスをまとめたものを返す
  int[] getAllTriangleIndices() {
    if(objects==null) return null;

    int numOfIndices = 0;
    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      for (int j=0; j<o.faces.length; j++) {
        MQOFace f = o.faces[j];
        if(f.num>=3) numOfIndices += 3; // 3 = triangle
        if(f.num>=4) numOfIndices += 3; // 四角形ポリゴンはもう１枚Triangleを足す
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

  // 描画
  void draw() {
    if(objects==null) return;

    pushStyle();

    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);

      // ローカル座標などを設定
      pushMatrix();
      translate(o.translation.x, o.translation.y, o.translation.z);
      scale(o.scale.x, o.scale.y, o.scale.z);
      rotateY(o.rotation.y); rotateX(o.rotation.x); rotateZ(o.rotation.z); // HPB回転

      // オブジェクト描画
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

  // オブジェクト描画
  private void drawObject(MQOObject o, byte envMapMode) {
    PMatrix3D matrix = new PMatrix3D();
    getMatrix(matrix);
    PVector cameraPos = new PVector(-matrix.m03, -matrix.m13, -matrix.m23);
    matrix.m03 = matrix.m13 = matrix.m23 = 0.0f; // 3x3でよい

    // シェーディングモードを設定
    byte nowShading = (shadingMode==SHADING_AUTO) ? o.shading : shadingMode;
    if(nowShading==SHADING_WIREFRAME) noFill();
    else noStroke();
    
    // オブジェクトをベタに描画
    int faceVNum = -1;
    int materialIndex = -1;
    PImage img = null;
    for (int j=0; j<o.faces.length; j++) {
      MQOFace f = o.faces[j];

      // マテリアルなどの設定
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

      // ポリゴン描画
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
            // 反射マッピング
            matrix.mult(n, uvn);
            uvn.normalize();
            uvn.x *= -1.0f;
            uvn.y *= -1.0f;
          } else {
            // 屈折マッピング
            PVector lv = new PVector();
            matrix.mult(v, lv);
            PVector e = PVector.sub(cameraPos, lv);
            e.normalize();
            float factor = 0.15f;  // 0～2
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

  // チャンク行を取得
  private int findChunkLine(String chunkName, String[] lines, int startLine) {
    for(int i=startLine; i < lines.length; i++) {
      if(lines[i].indexOf(chunkName)>=0) {
        //println(lines[i]);
        return i;
      }
    }
    return -1;
  }

  // 文字列をパラメータに分割
  private String[] splitArg(String str) {
    return splitTokens(str, " \t()\"{}");
  }

  // 該当パラメータindexを取得
  private int findArg(String name, int valueNum, String[] args, int startArg) {
    for(int i=startArg; i<args.length; i++) {
      if(args[i].equalsIgnoreCase(name) && i+valueNum<args.length) {
      //if(args[i].compareToIgnoreCase(name)==0 && i+valueNum<args.length) {
        return i;
      }
    }
    return -1;
  }

  // 各種パラメータ値を指定型で取得
  private boolean getBoolean(String name, String[] args, int startArg, boolean defaultVal) {
    return getInt(name, args, startArg, int(defaultVal))!=0;
  }

  private byte getByte(String name, String[] args, int startArg, int defaultVal) {
    return byte(getInt(name, args, startArg, defaultVal));
  }

  private int getInt(String name, String[] args, int startArg, int defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return int(args[i+1]);
    } else return defaultVal;
  }

  private float getFloat(String name, String[] args, int startArg, float defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return float(args[i+1]);
    } else return defaultVal;
  }

  private String getString(String name, String[] args, int startArg, String defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return args[i+1];
    } else return defaultVal;
  }

  private color getColor(String name, String[] args, int startArg, color defaultVal) {
    int i = findArg(name, 3, args, startArg);
    if(i>=0) {
      return color(float(args[i+1])*255, float(args[i+2])*255, float(args[i+3])*255);
    } else return defaultVal;
  }

  private color getColorGray(String name, String[] args, int startArg, color defaultVal) {
    int i = findArg(name, 1, args, startArg);
    if(i>=0) {
      return color(float(args[i+1])*255);
    } else return defaultVal;
  }
  
  private PVector getVector(String name, String[] args, int startArg, PVector defaultVal) {
    int i = findArg(name, 3, args, startArg);
    if(i>=0) {
      return new PVector(float(args[i+1]), float(args[i+2]), float(args[i+3]));
    } else return new PVector(defaultVal.x, defaultVal.y, defaultVal.z);
  }

  // マテリアルの読み込み
  private int parseMaterialChunk(String[] lines, int startLine) {
    int cur = startLine;
    cur = findChunkLine("Material", lines, cur);
    if(cur < 0) return -1;

    String[] args = splitArg(lines[cur++]);
    if(args.length <= 1) return -1;
    int num = int(args[1]);
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

  // オブジェクトの読み込み
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

    // パラメータ
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
    
    // 頂点
    args = splitArg(lines[cur++]);
    if(args.length <= 1) return -1;
    int num = int(args[1]);
    if(num<=0) return -1;
    
    o.vertices = new PVector[num];
    o.normals = new PVector[num];
    for(int i=0; i<num; i++) {
      args = splitArg(lines[cur++]);
      if(args.length<3) return -1;
      o.vertices[i] = new PVector(float(args[0]), -float(args[1]), float(args[2]));
      o.normals[i] = new PVector(0, 0, 0);
    }

    // 面
    cur = findChunkLine("face", lines, cur);
    if(cur < 0) return -1;

    args = splitArg(lines[cur++]);
    if(args.length <= 1) return -1;
    num = int(args[1]);
    if(num<=0) return -1;

    o.faces = new MQOFace[num];
    for(int i=0; i<num; i++) {
      args = splitArg(lines[cur++]);
      if(args.length<1) return -1;

      MQOFace face = new MQOFace();
      face.num = byte(int(args[0]));
      if(face.num<3 || face.num>4) return -1;

      face.index = new int[face.num];
      face.u = new float[face.num];
      face.v = new float[face.num];

      int c = findArg("V", face.num, args, 1);
      if(c<0) return -1;
      for(int j=0; j<face.num; j++) face.index[j] = int(args[c+1+j]);

      face.materialIndex = getByte("M", args, 1, -1);

      c = findArg("UV", face.num*2, args, 1);
      if(c>=0) {
        for(int j=0; j<face.num; j++) {
          face.u[j] = float(args[c+1+j*2]);
          face.v[j] = float(args[c+2+j*2]);
        }
      }
      o.faces[i] = face;
    }

    objects.add(o);
    return cur;
  }

  // 頂点法線計算
  private void computeNormals() {
    if(objects==null) return;

    for (int i=0; i<objects.size(); i++) {
      MQOObject o = objects.get(i);
      if(!o.visible) continue;

      // 頂点法線計算
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

      // スムージング角を見て頂点法線を修正
      for (int j=0; j<o.faces.length; j++) {
        MQOFace f = o.faces[j];
        PVector fn = o.getFaceNormal(j);
        for (int k=0; k<f.num; k++) {
          PVector vn = o.normals[f.index[k]];
          float facet = degrees( acos(PVector.dot(fn, vn)) );
          if(facet > o.facet) {
            o.normals[f.index[k]].set(fn); // 面法線を使ってエッジを鋭く
          }
        }
      }
    }
  }

  // 面をソート
  private void sortFaces() {
    if(objects==null) return;

    // マテリアル順、面の頂点数順でソート用の比較を行うクラス
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