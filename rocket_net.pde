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
int data[];
int angle;


void setup() 
{
  size(1280, 1280);
  background(204);
  stroke(0);
  frameRate(15); // Slow it down a little
  // Connect to the server's IP address and port
  c = new Client(this, "127.0.0.1", 12345); // Replace with your server's IP and port
}

void draw() 
{
  if (mousePressed == true) {
    // Draw our line
    stroke(255);
    line(pmouseX, pmouseY, mouseX, mouseY);
    // Send mouse coords to other person
    c.write(0+" "+mouseX + " " + mouseY + "\n");
  }
  
  // Receive data from server
  if (c.available() > 0) {
    input = c.readString();
    input = input.substring(0, input.indexOf("\n")); // Only up to the newline
    data = int(split(input, ' ')); // Split values into an array
    // Draw line using received coords
    stroke(0);
    line(data[0], data[1], data[2], data[3]);
  }
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
  background(204);
    fill(255);
  textSize(26);
  text(angle, 10, 35);

}
