import gab.opencv.*;
import processing.video.*;

Capture rawVideo;
OpenCV cv;
boolean initialFrameCaptured;
PImage initialFrame, diff;

ArrayList<Contour> contours;

void setup() {
  size(640, 480);
  rawVideo = new Capture(this, 640, 480);
  cv = new OpenCV(this, 640, 480);
  
  rawVideo.start();
  initialFrameCaptured = false;
}
void draw() {
  if (rawVideo.available()) {
    rawVideo.read();
    
    cv.useGray();
    
    cv.loadImage(rawVideo);
    cv.blur(20);
    
    if (!initialFrameCaptured) {
      initialFrame = cv.getSnapshot();
      initialFrameCaptured = true;
    }
    
    cv.diff(initialFrame);
    cv.threshold(45);
    cv.dilate();
    contours = cv.findContours();
    println("found " + contours.size() + " contours");
    diff = cv.getSnapshot();
    image(diff, 0, 0);
  }
}