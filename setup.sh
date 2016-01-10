#!/bin/bash

cd ~/desktop
echo "creating directories..."
mkdir motionPlayer && cd motionPlayer && \
mkdir videos
echo "checking if VLC player is installed..."
if [ -a /Applications/VLC.app ] # check if file exists
    then
    echo "VLC already installed, skipping download..."
else
    echo "downloading VLC media player..."
    curl -O http://mirror.de.leaseweb.net/videolan/vlc/2.2.1/macosx/vlc-2.2.1.dmg && \
    hdiutil attach -quiet vlc-2.2.1.dmg && \
    cd /Volumes/vlc-2.2.1 && \
    echo "copying VLC into Applications folder..."
    cp -R VLC.app Applications
fi
cd ~/desktop/motionPlayer
echo "editing VLC settings file..."
curl -O --silent https://raw.githubusercontent.com/edsammy/motionPlayer/master/vlcrc && \
if [ -d ~/Library/Preferences/org.videolan.vlc ] # check if directory exists
    then
    echo "VLC settings folder already exists..."
else
    echo "creating VLC settings folder..."
    #echo "enter password to create folder..."
    mkdir ~/Library/Preferences/org.videolan.vlc
fi
cp vlcrc ~/Library/Preferences/org.videolan.vlc
echo "downloading motionPlayer.zip..."
curl -O https://raw.githubusercontent.com/edsammy/motionPlayer/master/motionPlayer.zip
echo "unzipping app..."
unzip -q motionPlayer.zip # unzip quietly
echo "cleaning up..."
cd /Volumes && \
hdiutil detach -quiet vlc-2.2.1
cd ~/desktop/motionPlayer
rm vlc-2.2.1.dmg
rm vlcrc
rm motionPlayer.zip
if [ -a /Library/PreferencePanes/JavaControlPanel.prefpane ] # check if JRE is installed
    then
    echo "complete!"
else
    echo "***** setup not complete! ******"
    echo "You must install the Java Runtime Environment (JRE) in order to run the MotionPlayer"
    echo "Please install from http://www.java.com/en/download"
    echo "After installing the JRE you DO NOT need to run this setup tool again."
fi