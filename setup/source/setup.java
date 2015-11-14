import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class setup extends PApplet {

/*
Setup tool for the Motion Video Player
code by Eddie Samuels for Caroline Young
*/

String videosPath, VLCPath;
boolean done;

public void setup() {
  
  done = false;
  background(51);
  textSize(14);
}

public void draw() { 
  // draw() must be present for mousePressed() to work
  if (!done) {
    background(51);
    text("Click anywhere to select the path to VLC player \nand the folder where your videos are", 50, 75); 
  } else {
    background(51);
    text("Setup complete! Click anywhere to exit.", 50, 75); 
  }
}

public void mousePressed() {
  if (!done) {
    selectFolder("select folder where videos are located", "videoFolderSelected");
    selectInput("select the VLC app", "VLCSelected");
  } else {
    exit();
  }
}

public void videoFolderSelected(File selection) {
 if (selection == null) {
   exit();
 } else {
   videosPath = selection.getAbsolutePath();
   String[] importSettings = {videosPath, VLCPath};
   saveStrings("settings.txt", importSettings);
   done = true;
 }
}

public void VLCSelected(File selection) {
 if (selection == null) {
   exit();
 } else {
   VLCPath = selection.getAbsolutePath();
 }
}
  public void settings() {  size (400,200); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "setup" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
