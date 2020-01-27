//based on examples from Eric Blues Brain Grapher 
//https://github.com/ericblue/Processing-Brain-Grapher 
//and genekogans shader examples
//https://github.com/genekogan/Processing-Shader-Examples 
import neurosky.*; 
import org.json.*; 
import grafica.*;
import java.util.Random;
import processing.sound.*;

int version=0; //for future use

boolean playsound=true; //play sound or not
boolean showstrobe=true; //turn strobing when high att on/off
boolean shownumbers=true; //turn text/numbers on/off
boolean showgraph=true; //turn att/med graphs on/off
boolean showshader=true; //turn shader/red animation on/off

boolean playing=false; 

int interval=1000; //how often to save sensor data; 1000 millis standard
int attcol=#00FF00; //color of attention graph
int medcol=#8e44ad; //color of meditation graph
int maxYvalues=20; //number of values of graph to show at one time (how compressed/zoomed in)
float graphlinewidth=5.0; //thickness of graph line

int graphxscale=20;
int graphyscale=7;

ThinkGearSocket neuroSocket; 
int attention=10; 
int meditation=10; 
float eegdelta=15; 
float eegtheta=25; 
int eegloalpha=35; 
int eeghialpha=45; 
int eeglobeta=55; 
int eeghibeta=67; 
int eegmidgamma=75; 
int eeglogamma=85; 
int blink=95; 
int signal=200; 
PFont font; 
boolean blinker=false; 
int timer; 
int timer2=0; 
int millis2=0; 
int strober; 
int number = 0; 
boolean txtflash=true; 
float easing = 0.1; 
float attease; 
float medease; 
int timeease;
int place;

PShader blobbyShader; 
PGraphics pg; 

String[] date = new String[6];
String txtdate = "20190000000000";

PrintWriter output;

public GPlot plot2, plot3;

TriOsc oscAtt;
TriOsc oscMed;

void setup() { 

  // create oscillators
  oscAtt = new TriOsc(this);
  oscMed = new TriOsc(this);
  
  //setup for the two graphs

  plot2 = new GPlot(this);
  plot2.setPos(width/graphxscale, height/graphyscale);
  plot2.setDim(width-15*graphxscale, height/3);
  plot2.setYLim(0, 200);
  plot2.setLineColor(attcol);
  plot2.setLineWidth(graphlinewidth);
  plot2.deactivateZooming();
  plot2.deactivateCentering();
  plot2.deactivatePanning();
  plot2.setFixedYLim(true);

  plot3 = new GPlot(this);
  plot3.setPos(width/graphxscale, height/graphyscale);
  plot3.setDim(width-15*graphxscale, height/3);
  plot3.setYLim(0, 200);
  plot3.setLineColor(medcol);
  plot3.setLineWidth(graphlinewidth);
  plot3.deactivateZooming();
  plot3.deactivateCentering();
  plot3.deactivatePanning();
  plot3.setFixedYLim(true);

  //setup for the filename generation

  date[0] = String.valueOf(year());   // 2003, 2004, 2005, etc.
  date[1] = String.valueOf(month());  // Values from 1 - 12
  date[2] = String.valueOf(day());    // Values from 1 - 31
  date[3] = String.valueOf(hour());    // Values from 0 - 23
  date[4] = String.valueOf(minute());  // Values from 0 - 59
  date[5] = String.valueOf(second());  // Values from 0 - 59
  txtdate = join(date, "-");
  output = createWriter(txtdate+".txt"); 
  timer2 = millis();

  //setup communication with mindwave sensor

  ThinkGearSocket neuroSocket = new ThinkGearSocket(this); 
  try { 
    neuroSocket.start();
  } 
  catch (Exception e) { 
    //println("Is ThinkGear running??");
  } 

  // rest of setup

  size(1024, 720, P3D);  //use this line for windowed mode
  //fullScreen(P3D); //use this line for fullscreen
  background(0); 
  smooth(); 

  font = createFont("Verdana", 20); 
  textFont(font); 

  //for the shader

  pg = createGraphics(1024, 720, P3D); 
  blobbyShader = loadShader("blobby2.glsl");
} 

void draw() { 

  if (showshader) {
    blobbyShader.set("time", (float) millis()/1000.0); 
    blobbyShader.set("resolution", float(pg.width), float(pg.height)); 
    blobbyShader.set("depth", map(attease-medease, -100, 100, 0.24, 0.35)); 
    blobbyShader.set("rate", map(attease-medease, -100, 100, 0.40, 0.86)); 
    blobbyShader.set("alpha", 0.1); 
    blobbyShader.set("colr", map(attention-meditation, -100, 100, 0.49, 0.24)); 
    blobbyShader.set("colg", map(attention-meditation, -100, 100, 1, 0.1)); 
    blobbyShader.set("colb", map(attention-meditation, -100, 100, 1, 0)); 
    showShader();
  } else {
    background(0);
    smooth();
  }

  if (showstrobe) {
    showStrobe();
  }

  if (playsound) {

    if (!playing) {
      oscAtt.play();
      oscMed.play();
      playing=true;
    }

    float freqAtt=attease+300;
    //float ampAtt=map(attease-medease, -100, 100, 0.0, 0.4);
    float ampAtt=map(attease, 0, 100, 0.0, 0.4);
    float addAtt=0.0;
    float posAtt=1;
    oscAtt.set(freqAtt, ampAtt, addAtt, posAtt);

    float freqMed=medease+50;
    //float ampMed=map(attease-medease, -100, 100, 0.7, 0.0);
    float ampMed=map(medease, 0, 100, 0.0, 0.6);
    float addMed=0.0;
    float posMed=1;
    oscMed.set(freqMed, ampMed, addMed, posMed);
  }

  if (shownumbers) {
    showNumbers();
  }

  //data logger

  if (millis() - timer2 >= interval) { 
    millis2=millis();
    text(millis2, 30, 520);
    output.println(millis2 + "," + signal + "," + attention + "," + meditation + "," + eegdelta + "," + eegtheta + "," + eegloalpha + "," + eeghialpha + "," + eeglobeta + "," + eeghibeta + "," + eegmidgamma + "," + eeglogamma + "," + blink); // Write a line the file
    timer2 = millis();
  } 

  //easing for the animations

  timeease=millis();

  float targetatt = attention; 
  float attx = targetatt - attease; 
  attease += attx * easing; 

  float targetmed = meditation; 
  float medx = targetmed - medease; 
  medease += medx * easing; 

  if (showgraph) {
    plot2.addPoint(timeease, attease);
    plot3.addPoint(timeease, medease);
    place++;
    if (place>maxYvalues) {
      plot2.removePoint(0);
      plot3.removePoint(0);
    }
    showGraph();
  }
} 

//end main loop

//functions

void showStrobe() {
  if (attention >= 80 && millis() - strober > random(200, 2000)) { 
    background(random(255), random(255), random(255)); 
    strober = millis();
  }
} 

void showNumbers() {
  fill(255, 0, 0); 
  if (txtflash) { 
    text("LIVE BRAIN ACTIVITY VISUALIZER", 30, 40);
  } 
  if (millis() - timer >= 1000) { 
    txtflash = !txtflash; 
    timer = millis();
  } 
  text("BrainViz v.0.7:", 30, 70); 
  if (signal == 200) { 
    text("Waiting for brain...", 200, 70);
  }     
  if (signal == 0) { 
    text("Reading brain...", 200, 70);
  }     
  if (signal > 0 && signal < 200) { 
    text("Searching for brain...", 200, 70);
  }   

  text("sig "+signal, 30, 130);
  text("att "+attention, 30, 160);
  text("med "+meditation, 30, 190);
  text("delta "+eegdelta, 30, 220);
  text("theta "+eegtheta, 30, 250);
  text("loalpha "+eegloalpha, 30, 280);
  text("hialpha "+eeghialpha, 30, 310);
  text("lobeta "+eeglobeta, 30, 340);
  text("hibeta "+eeghibeta, 30, 370);
  text("midgamma "+eegmidgamma, 30, 400);
  text("logamma "+eeglogamma, 30, 430);
  text("blink "+blink, 30, 460);
  text(txtdate, 30, 490);


  //text(millis2, 30, 550);
  //text(timer2, 30, 580);
  //text(millis(), 30, 610);
}

void showGraph() {
  plot2.beginDraw();
  plot2.drawLines();
  plot2.endDraw();

  plot3.beginDraw();
  plot3.drawLines();
  plot3.endDraw();
}

void showShader() {
  pg.shader(blobbyShader); 
  pg.rect(0, 0, pg.width, pg.height); 
  image(pg, 0, 0);
}

//read all the data form the eeg sensor

void poorSignalEvent(int sig) { 
  signal=sig;
} 

void attentionEvent(int attentionLevel) { 
  attention = attentionLevel;
} 


void meditationEvent(int meditationLevel) { 
  meditation = meditationLevel;
} 

void blinkEvent(int blinkStrength) {
  blink=blinkStrength;
} 

void eegEvent(int delta, int theta, int low_alpha, int high_alpha, int low_beta, int high_beta, int low_gamma, int mid_gamma) { 
  eegdelta=log(delta); 
  eegtheta=log(theta); 
  eegloalpha=low_alpha; 
  eeghialpha=high_alpha; 
  eeglobeta=low_beta; 
  eeghibeta=high_beta; 
  eegmidgamma=mid_gamma; 
  eeglogamma=low_gamma;
} 

void rawEvent(int[] raw) { //we don't use the raw eeg data atm
}   

//keyhandler

void keyPressed() { 
  if (key == 's') { 
    println("Saving screenshot..."); 
    String s = txtdate + "-" + millis2 +".png"; 
    save(s); 
    number++; 
    println("Done saving.");
  } else if (key == ESC) { 
    println("Exiting..");
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
    try { 
      neuroSocket.stop();
      super.stop();
    } 
    catch (Exception e) { 
      //println("Is ThinkGear running??");
    } 
    exit(); // Stops the program
  } //else if (key == 't') { //for debugging purposes
  //delay(10000);
  // }
} 

void stop() { 
  neuroSocket.stop(); 
  super.stop();
} 