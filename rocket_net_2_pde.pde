/**
 * Shared Drawing Canvas (Client) 
 * by Alexander R. Galloway. 
 * 
 * The Processing Client class is instantiated by specifying a remote 
 * address and port number to which the socket connection should be made. 
 * Once the connection is made, the client may read (or write) data to the server.
 * Before running this program, start the Shared Drawing Canvas (Server) program.
 */


import processing.net.*;

Client c;
String input;
int[] data = new int[5];
int angle;
int number=0,d_number=0;
int hit = 0;
int hp=1000;
int ene_x, ene_y, ene_r, d_ene_x, d_ene_y;
;

void setup() 
{
  size(1280, 1280);
  stroke(0);
  frameRate(15); // Slow it down a little
  // Connect to the server's IP address and port
  c = new Client(this, "127.0.0.1", 12345); // Replace with your server's IP and port
}

void draw() 
{
  background(204);
  if (mousePressed == true) {
    // Draw our line
    stroke(255);
    line(pmouseX, pmouseY, mouseX, mouseY);
    // Send mouse coords to other person
    c.write(0+" "+mouseX + " " + mouseY + "\n");
  }
  
      // Receive data from client
    if (c.available() >0) {
      input = c.readString();
      input = input.substring(0, input.indexOf("\n")); // Only up to the newline
      data = int(split(input, " ")); // Split values into an array
      // Draw line using received coords
        hp=hp-100;
      if(data[0]==2){ //障害物生成時に受信
        number = data[1];
        ene_x = data[2];
      }else if(data[0]==5){
        ene_y = data[1];
        ene_r = data[2];
      }else if(data[0]==3){
        hp = 1000;
        hit = 0;
      }else if(data[0]==4){ //障害物死滅時に受信
        d_number = data[1]; 
//        d_ene_x = data[2];
//        d_ene_y = data[3];
        hit = hit+1;
        if(data[2]==1) hp = hp-100;
      }
    }
      //描画
        stroke(0,255,0);
        textSize(56);        
        fill(0,255,0);
        text("HP: "+hp, width/2, height/2);
        textSize(56);
        fill(0,255,0);
        text("HIT: "+hit, width/2, height/2+50);
        textSize(26);
        fill(0);
        text("NEW enemy No. "+number + " X:" + ene_x + " Y:" + ene_y + " R:"+ene_r, width/2, height/2+300);
        stroke(0,255,0);
       textSize(26);
        fill(0);
        text("DEAD enemy No. "+d_number, width/2, height/2+100);
        stroke(0,255,0);
 /*
  // Receive data from server
  if (c.available() > 0) {
    input = c.readString();
    input = input.substring(0, input.indexOf("\n")); // Only up to the newline
    data = int(split(input, ' ')); // Split values into an array
    // Draw line using received coords
    stroke(0,255,0);
    textSize(56);
    fill(0,255,0);
    text("HIT: "+data[1], width/2, height/2);

    line(data[0], data[1], data[2], data[3]);
  }*/
}

void keyPressed() {
  if( key == '1' ){
    angle = 1;
  }
  if( key == '2' ){
    angle = 2;
  }
  if( key == '3' ){
    angle = 3;
  } 
  if( key == '4' ){
    angle = 0;
  }
  c.write(1+" "+ angle + "\n");
  fill(255);
  textSize(26);
  text(angle, 10, 35);
}
