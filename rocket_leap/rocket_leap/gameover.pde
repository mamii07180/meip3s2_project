void gameover(float edist){
    client.write(6 +"\n"); 
    //message
    noStroke();
    textSize(86);
    fill(255);
    if ( hp<=0 ) {
        fill(255, 0, 255);
        text("YOU WIN!!", 30, 100);
        textSize(50);
        text("The Earth was saved.", 30, 150);
    }
    else {
        fill(255, 0, 255);
        text("YOU LOSE...", 30, 100);
        textSize(50);
    }
    //data
    fill(255);
    text("HIT : ", 30, h2);
    fill(0,255,0);
    text(hit, 150, h2);
    fill(255);
    text("HP  : ", 30, h2+50);
    fill(0,255,0);
    text(hp, 150, h2+50);
    fill(255);
    text("Distance of Rocket-Earth : ", 30, h2+100);
    fill(0,255,0);
    text(edist+" ×10000km", 700, h2+100);
    fill(255);
    text("You made ", 30, h2+150);
    fill(0,255,0);
    text(enecount, 300, h2+150);
    fill(255);
    text("stars.", 350, h2+150);
    textSize(30);
    fill(0,255,0);
    text(enecountb, 100, h2+180);
    fill(255);
    text("stars were Special.", 130, h2+180);
    //replay-box
    int replayX = 700;
    int replayY = (int)100;
    if (replayX-90<=mouseX && mouseX<=replayX+90 && replayY-30<=mouseY && mouseY<=replayY+30) fill(255, 0, 255);
    else  fill(255);
    rect(replayX-90, replayY-30, 180, 60);
    textSize(50);
    fill(0);
    textAlign(CENTER, CENTER);
    text("REPLAY", replayX, replayY);   
    fill(255);
    text(" <<<", replayX+140, replayY);   
    textAlign(LEFT, LEFT);   
    g2=fingerReplay(x[0], x[2], x[4], Re);
    if (g2==1.0) { //replayが押されたら
        client.write(3+ "\n"); //向こうにリセットを知らせる
        replace();
    }
    //↓作業用------------
    if(mousePressed && replayX-90<=mouseX && mouseX<=replayX+90 && replayY-30<=mouseY && mouseY<=replayY+30){
        client.write(3+ "\n"); //向こうにリセットを知らせる
        replace();
    }
    //↑作業用------------
}