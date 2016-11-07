/* 
Motion Video Player
code by Eddie Samuels for Caroline Young

This sketch iterfaces with VLC media player and skips to the next video
when motion is detected using OpenCV.

Check out https://github.com/edsammy/cyoung for installation instructions.
*/

import gab.opencv.*;
import processing.video.*;

// Packages used for getting unique camera names
import java.util.HashSet;
import java.util.Arrays;

// Packages used to communicate with VLC command line tool
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

Capture rawVideo; // video object used for webcam capture
OpenCV cv; // open cv object to do processing of motion

// Variable decalarations
boolean debug, initialFrameCaptured, personInView, queueNextVideo, camsListed, camSelected, setupComplete, vlcLoaded, run, countdown;
PImage initialFrame, cropped, raw, diff, threshold, contour;
float area;
ArrayList<Contour> contours;
BufferedWriter out;
BufferedReader in;
String videosPath, VLCPath, camSelectionName, dateStamp, timeStamp;
String[] camNames;
int captureWidth, captureHeight, startTime, currentTime, countDownDelay, elapsedTime;

int areaThresh = 50000;

void setup() {
  debug = true;
  camsListed = false;
  camSelected = false;
  setupComplete = false;
  vlcLoaded = false;
  run = false;

  countDownDelay = 5500;

  videosPath = sketchPath()+"/videos";
  VLCPath = "/Applications/VLC.app";

  // get datetime stamps for error logging
  dateStamp = String.valueOf(month())+"/"+String.valueOf(day())+"/"+String.valueOf(year());
  timeStamp = String.valueOf(hour())+":"+String.valueOf(minute());

  size(960, 720);
  textSize(32);
  background(100);
  text("Motion Video Player", 320, 55); 
 
  textSize(14);
}
    
void draw() {
  if (!camsListed) {  
    // Get unique camera names so the user can select the internal iSight webcam or external USB webcam
    camNames = getCameraNames();
    
    // Only give the user the option to select a cam if there are multiple
    if (camNames.length > 1) {
      text("Select which camera you want to use with the numerical keys", 270, 150);
      for (int i = 0; i < camNames.length; i++) {
        text((i+1) + ") " + camNames[i],330,(170+(i*20)));
      }
    } else {
      camSelectionName = camNames[0];
      camSelected = true;
    }
    camsListed = true; 
    captureWidth = 480;
    captureHeight = 360;
  }
  
  if (camSelected) { // dont start the camera capture until a cam has been selected
    if (!setupComplete) {
      text("Press 's' to capture background and begin motion detection", 270, 150);
      
      rawVideo = new Capture(this, captureWidth, captureHeight, camSelectionName); // (parent, width, height, camName)
      cv = new OpenCV(this, captureWidth, captureHeight);
    
      rawVideo.start(); // Start webcam capturing
      initialFrameCaptured = false;
      personInView = false;
      queueNextVideo = true;
      setupComplete = true;
    }
  }
  
  // Run a countdown timer and show the user before capturing the background frame
  if (!run) {
    if (countdown) {
      if (rawVideo.available()) {
        rawVideo.read(); // get frame from webcam
        image(rawVideo, 0, 100, captureWidth*2, captureHeight*2);
      }
      currentTime = millis();
      elapsedTime = currentTime - startTime;
      if (elapsedTime < countDownDelay) {
        text("capturing background in:", 25, 155);
        text((countDownDelay - elapsedTime)/(1000), 200, 155);
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
      //cropped = rawVideo.get(0,0,100,100); //crop image to trigger zone
      cv.loadImage(rawVideo); // pass frame to openCV
      
      // Use color to display background to the user
      cv.useColor();
      raw = cv.getSnapshot();
      
      cv.useGray(); // grayscale for easier processing
      cv.blur(20);
      
      if (!initialFrameCaptured) {
        initialFrame = cv.getSnapshot();
        initialFrameCaptured = true;
        image(raw, 0, 100, captureWidth*2, captureHeight*2);
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
        if (debug) {
          println(area);
        }
        // See if the first contour is greater than the min area
        // (only need to look at the first one since they are sorted by size)
        if (area >= areaThresh) {
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
        image(raw, 0, 0);
        image(diff, captureWidth, 0);
        image(contour, 0, captureHeight);
        image(threshold, captureWidth, captureHeight);
      }
    }
  }
}

// Returns unique cameras attached to the computer
// https://forum.processing.org/two/discussion/11643/capture-list-function-finds-wrong-number-of-cameras
String[] getCameraNames()
{
  String[] list = Capture.list();
  for (int i=0; i < list.length; i++)
  {
    String[] chunks = split(list[i], ',');
    chunks = split(chunks[0], '=');
    list[i] = chunks[1];
  }
  String[] unique = new HashSet<String>(Arrays.asList(list)).toArray(new String[0]);
  return unique;
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
  if (camsListed) {
    if (!camSelected) {
      int keyASCII = int(key);
      if (keyASCII >= 49 && keyASCII <= (camNames.length + 48)) { // if key 1 to the max number of elements in camNames is pressed
        camSelectionName = camNames[keyASCII - 49]; // convert the ASCII number back to its numerical key minus 1 since arrays are 0 indexed
        camSelected = true;
        
        // Erase the screen so the user knows the selection was made
        textSize(32);
        background(100);
        text("Motion Video Player", 320, 55); 
        textSize(14);
      }
  } else {
      if (key == 's') {
        startTime = millis();
        countdown = true;
      }
    }
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

void dispose() { // runs on exit of sketch
  // Make sure VLC quits when the motionPlayer closes
  String[] killVLC = {"pkill", "-9", "VLC"};
  exec(killVLC);
}
  