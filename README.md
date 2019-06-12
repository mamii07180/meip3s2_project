# meip3s2_project

## 概要
## kinect班
スペースシャトルの操縦
### やること1
* kinectから手先の高さを測定
* 右（左）手をあげると右（左）に旋回（回転+並進）
* 手を挙げていないときは直進
### やること2
* 手を開けているときはビームを出す
### 送信データ
* 機体の座標
* 破壊したオブジェクトのリスト番号
* (玉の座標）
### 受信データ
* 障害物の出現位置と半径

## leap班
障害物の配置
### やったこと1
* ロケットをマウス追従して動かす
* ロケットからビームを出す・惑星に当たると消える
* マウス右ボタンをドラッグしたサイズ・位置の障害物を配置する
* HP/HIT数を表示　10回当たると終了
* リプレイボタンを設置
* LEAP Motionでカーソル表示
* プロジェクターで投影・位置調整
* LEAP motionからサイズ・位置の障害物を配置する
* kinect側にHIT数・HP・敵の死滅情報を送信
### やること1
* kinect側とロケット位置を連携
