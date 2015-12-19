/* 
Motion Video Player
code by Eddie Samuels for Caroline Young

This sketch iterfaces with VLC media player and skips to the next video
when motion is detected using OpenCV.

Check out https://github.com/edsammy/cyoung for installation instructions.
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
boolean debug, initialFrameCaptured, personInView, queueNextVideo, vlcLoaded, run, countdown;
PImage initialFrame, raw, diff, threshold, contour;
float area;
ArrayList<Contour> contours;
BufferedWriter out;
BufferedReader in;
String videosPath, VLCPath, dateStamp, timeStamp;
int startTime, currentTime, countDownDelay, elapsedTime;

void setup() {
  debug = false;
  vlcLoaded = false;
  run = false;

  size(640, 580);
  textSize(32);
  background(100);
  text("Motion Video Player", 170, 55); 
  textSize(14);
  text("Press 's' to capture background and begin motion detection", 120, 150);
  
  videosPath = sketchPath()+"/videos";
  VLCPath = "/Applications/VLC.app"; 
  
  rawVideo = new Capture(this, 320, 240);
  cv = new OpenCV(this, 320, 240);
  
  rawVideo.start(); // Start webcam capturing
  initialFrameCaptured = false;
  personInView = false;
  queueNextVideo = true;
  
  // get datetime stamps for error logging
  dateStamp = String.valueOf(month())+"/"+String.valueOf(day())+"/"+String.valueOf(year());
  timeStamp = String.valueOf(hour())+":"+String.valueOf(minute());
   
  countDownDelay = 5500;
  textSize(20);
}
    
void draw() {
  if (!run) {
    if (countdown) {
      if (rawVideo.available()) {
        rawVideo.read(); // get frame from webcam
        image(rawVideo, 0, 100, 640, 480);
      }
      currentTime = millis();
      elapsedTime = currentTime - startTime;
      if (elapsedTime < countDownDelay) {
        text("capturing background in:", 25, 155);
        text((countDownDelay - elapsedTime)/(1000), 280, 155);
      }
      else {
        countdown = false;
        run = true;
      }
    }
  }
  else { // if user has initialized
    if (!vlcLoaded) {
      initVLC();
    }
    if (rawVideo.available()) {
      rawVideo.read(); // get frame from webcam
      cv.loadImage(rawVideo); // pass frame to openCV
      
      // Use color to display background to the user
      cv.useColor();
      raw = cv.getSnapshot();
      
      cv.useGray(); // grayscale for easier processing
      cv.blur(20);
      
      if (!initialFrameCaptured) {
        initialFrame = cv.getSnapshot();
        initialFrameCaptured = true;
        image(raw, 0, 100, 640, 480);
        text("background", 25, 155); 
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
        image(raw, 0,100);
        image(diff, 320, 100);
        image(contour, 0, 340);
        image(threshold, 320, 340);
      }
    }
  }
}

void initVLC() {
  String[] openVLC = {VLCPath+"/Contents/MacOS/VLC", "--fullscreen","--loop", "--random", "--repeat", "--mouse-hide-timeout=100", "--no-video-title-show", videosPath};
  
  // got setup and commands from VLCj:
  // http://berry120.blogspot.com/2011/07/using-vlcj-for-video-reliably-with-out.html
  try {
    Process p = Runtime.getRuntime().exec(openVLC);
    out = new BufferedWriter(new OutputStreamWriter(p.getOutputStream()));
    
    // used to read the output from the command line, not currently being used
    //in = new BufferedReader(new InputStreamReader(p.getInputStream()));
  } catch (Exception err) {
    String[] errorOutput = {dateStamp, timeStamp, "VLC failed to load"};
    saveStrings("error.log", errorOutput);
    exit();
  }
  vlcLoaded = true;
}

void keyPressed() {
  if (key == 's') {
    startTime = millis();
    countdown = true;
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
    String[] errorOutput = {dateStamp, timeStamp, "next video command failed"};
    saveStrings("error.log", errorOutput);
    exit();
  }
}

void dispose() {
  // Make sure VLC quits when the motionPlayer closes
  String[] killVLC = {"pkill", "-9", "VLC"};
  exec(killVLC);
}
  