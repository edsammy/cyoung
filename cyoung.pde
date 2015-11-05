import gab.opencv.*;
import processing.video.*;

Capture rawVideo;
OpenCV cv;
boolean initialFrameCaptured, personInView, queueNextVideo;
PImage initialFrame, raw, diff, threshold, contour;
float area;
ArrayList<Contour> contours;

void setup() {
  size(640, 480);
  rawVideo = new Capture(this, 320, 240);
  cv = new OpenCV(this, 320, 240);
  
  rawVideo.start();
  initialFrameCaptured = false;
  personInView = false;
  queueNextVideo = true;
  
  playRandomVideo();
}

void draw() {
  if (rawVideo.available()) {
    rawVideo.read();
    cv.loadImage(rawVideo);
    cv.useColor();
    raw = cv.getSnapshot();
    cv.useGray();
    cv.blur(20);
    
    if (!initialFrameCaptured) {
      initialFrame = cv.getSnapshot();
      initialFrameCaptured = true;
    }
    
    cv.diff(initialFrame); // compare the current video frame to the initial frame
    diff = cv.getSnapshot(); // snapshot for dislpay
    cv.threshold(45); // whitespace where image is above threshold
    threshold = cv.getSnapshot(); // snapshot for dislpay
    cv.dilate(); // used to find contours
    contours = cv.findContours(true,true); //find holes, sort by areas
    contour = cv.getSnapshot(); // snapshot for dislpay
    
    if (contours.size() == 0) {
        println("No one in view");
        personInView = false;
        queueNextVideo = true;
    }
    
    // Check if any contours (new things in the frame when compared to the original) exist
    if (contours.size() > 0) {
      area = contours.get(0).area();
      // See if the first contour is greater than the min area
      // (only need to look at the first one since they are sorted by size)
      if (area >= 1000) {
        println("Person in view!");
        personInView = true;
        if (queueNextVideo) {
          playRandomVideo();
          queueNextVideo = false;
        }
        else {
          queueNextVideo = false; 
        }
      }
    } else {
      println("Min area not met!");
      personInView = false;
      queueNextVideo = true;
    }
    
    // Live view from camera used for development
    image(raw, 0,0);
    image(diff, 320, 0);
    image(contour, 0, 240);
    image(threshold, 320, 240);
  }
}

void playRandomVideo() {
  String[] quitPreviousInstanceOfVLC = {"osascript", "-e" ,"quit app \"vlc.app\""};
  String[] openRandomVideo = {"/Applications/VLC.app/Contents/MacOS/VLC", "--loop", "--random", "/Users/eddiemsamuels/Desktop/cyoung/data"};
  
  exec(quitPreviousInstanceOfVLC);
  exec(openRandomVideo);
}