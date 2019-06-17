/**

 * Shared Drawing Canvas (Server) 

 * by Alexander R. Galloway. 

 * 

 * A server that shares a drawing canvas between two computers. 

 * In order to open a socket connection, a server must select a 

 * port on which to listen for incoming clients and through which 

 * to communicate. Once the socket is established, a client may 

 * connect to the server and send or receive commands and data.

 * Get this program running and then start the Shared Drawing

 * Canvas (Client) program so see how they interact.

 */





import processing.net.*;



Server s;

Client c;

String input;
int a = 0;
int data[];
 int x, y,r;
int k = 0;

void setup() 

{

  size(450, 255);

  background(204);

  stroke(0);

  frameRate(60); // Slow it down a little

  s = new Server(this, 12345); // Start a simple server on a port

}



void draw() 


{
 int t; 

  if (mousePressed == true) {
    if(keyPressed == true && key ==' '){
      t = 4;
      s.write(t + " " + a + "\n");
      a += 1;
      delay(100);
    }else{
    // Draw our line
    x = (int)((mouseX - width/2) * 10);
    // Send mouse coords to other person
    y = (int)((mouseY - height/2) * 10);
    t = 2;
    r = (int)(random(25)*2);
    s.write(t + " " + k + " " + x + " " + y + " " + r + "\n");
    k += 1;
    delay(100);
  }
  }
  
  
  

  // Receive data from client

  c = s.available();

  if (c != null) {

    input = c.readString();

    input = input.substring(0, input.indexOf("\n")); // Only up to the newline

    data = int(split(input, ' ')); // Split values into an array

    // Draw line using received coords

    stroke(0);

    line(data[0], data[1], data[2], data[3]);

  }

}