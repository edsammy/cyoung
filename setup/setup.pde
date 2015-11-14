/*
Setup tool for the Motion Video Player
code by Eddie Samuels for Caroline Young
*/

String videosPath, VLCPath;
boolean done;

void setup() {
  size (400,200);
  done = false;
  background(51);
  textSize(14);
}

void draw() { 
  // draw() must be present for mousePressed() to work
  if (!done) {
    background(51);
    text("Click anywhere to select the path to VLC player \nand the folder where your videos are", 50, 75); 
  } else {
    background(51);
    text("Setup complete! Click anywhere to exit.", 50, 75); 
  }
}

void mousePressed() {
  if (!done) {
    selectFolder("select folder where videos are located", "videoFolderSelected");
    selectInput("select the VLC app", "VLCSelected");
  } else {
    exit();
  }
}

void videoFolderSelected(File selection) {
 if (selection == null) {
   exit();
 } else {
   videosPath = selection.getAbsolutePath();
   String[] importSettings = {videosPath, VLCPath};
   saveStrings("settings.txt", importSettings);
   done = true;
 }
}

void VLCSelected(File selection) {
 if (selection == null) {
   exit();
 } else {
   VLCPath = selection.getAbsolutePath();
 }
}