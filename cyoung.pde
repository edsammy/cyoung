/* 
Motion Video Player
code by Eddie Samuels for Caroline Young

This sketch relies on a file named settings.txt which contains the 
full path of the videos one wants to play on the first line and the
full path of VLC.app. You can create the file manually or use the
included setup tool (setup.app).
*/

import gab.opencv.*;
import processing.video.*;

// Packages used to communicate with VLC command line tool
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

Capture rawVideo; // video object used for webcam capture
OpenCV cv; // open cv object to do processing of motion

// Variable decalarations
boolean debug, initialFrameCaptured, personInView, queueNextVideo, settingsFound;
PImage initialFrame, raw, diff, threshold, contour;
float area;
ArrayList<Contour> contours;
BufferedWriter out;
BufferedReader in;
String videosPath, VLCPath;


void setup() {
  debug = false;
  settingsFound = false;

  size(640, 480);
  textSize(32);
  background(51);
  text("Motion Video Player", 170, 55); 
  
  // open settings.txt file to read where to load videos and VLC from
  try {
    String[] importSettings = loadStrings("setup/settings.txt");
    videosPath = importSettings[0];
    VLCPath = importSettings[1]; 
    settingsFound = true;
  } catch (Exception err) {
    String[] setupPath = {"open", sketchPath()+"/setup/setup.app"}; 
    exec(setupPath);
    exit();
  }
  
  if (settingsFound){
    rawVideo = new Capture(this, 320, 240);
    cv = new OpenCV(this, 320, 240);
    
    rawVideo.start(); // Start webcam capturing
    initialFrameCaptured = false;
    personInView = false;
    queueNextVideo = true;
    
    initVLC();
  }
}
    
void draw() {
  if (rawVideo.available()) {
    rawVideo.read();
    cv.loadImage(rawVideo);
    if (debug) {
      cv.useColor();
      raw = cv.getSnapshot();
    }
    cv.useGray();
    cv.blur(20);
    
    if (!initialFrameCaptured) {
      initialFrame = cv.getSnapshot();
      initialFrameCaptured = true;
    }
    
    cv.diff(initialFrame); // compare the current video frame to the initial frame
    
    if (debug) diff = cv.getSnapshot(); // snapshot for dislpay
    
    cv.threshold(45); // whitespace where image is above threshold
    
    if (debug) threshold = cv.getSnapshot(); // snapshot for dislpay
    
    cv.dilate(); // used to find contours
    
    contours = cv.findContours(true,true); //find holes, sort by areas
    
    if (debug) contour = cv.getSnapshot(); // snapshot for dislpay
    
    if (contours.size() == 0) {
        if (debug) println("No one in view");
        personInView = false;
        queueNextVideo = true;
    }
    
    // Check if any contours (new things in the frame when compared to the original) exist
    if (contours.size() > 0) {
      area = contours.get(0).area();
      // See if the first contour is greater than the min area
      // (only need to look at the first one since they are sorted by size)
      if (area >= 500) {
        if (debug) println("Person in view!");
        personInView = true;
        if (queueNextVideo) {
          playNextVideo();
          queueNextVideo = false;
        }
        else {
          queueNextVideo = false; 
        }
      }
    } else {
      if (debug) println("Min area not met!");
      personInView = false;
      queueNextVideo = true;
    }
    
    // Live view from camera used for development
    if (debug) {
      image(raw, 0,0);
      image(diff, 320, 0);
      image(contour, 0, 240);
      image(threshold, 320, 240);
    }
  }
}

void initVLC() {
  String[] openVLC = {VLCPath+"/Contents/MacOS/VLC", "--fullscreen","--loop", "--random", videosPath};
  
  // got setup and commands from VLCj:
  // http://berry120.blogspot.com/2011/07/using-vlcj-for-video-reliably-with-out.html
  try {
    Process p = Runtime.getRuntime().exec(openVLC);
    out = new BufferedWriter(new OutputStreamWriter(p.getOutputStream()));
    
    // used to read the output from the command line, not currently being used
    //in = new BufferedReader(new InputStreamReader(p.getInputStream()));
  } catch (Exception err) {
    exit();
  }
}

void playNextVideo() {
  if (debug) println("next video command sent");
  
  // got setup and commands from VLCj:
  // http://berry120.blogspot.com/2011/07/using-vlcj-for-video-reliably-with-out.html
  try {
    // send next command to VLC
    out.write("next\n");
    out.flush();
  } catch (Exception err) {
    exit();
  }
}