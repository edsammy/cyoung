#!/bin/bash

cd ~
echo "creating directories..."
mkdir motionPlayer && cd motionPlayer
mkdir videos
echo "downloading VLC media player..."
curl -O http://mirror.de.leaseweb.net/videolan/vlc/2.2.1/macosx/vlc-2.2.1.dmg && \
echo "moving VLC into Applications folder..."
cd /Volumes && \
hdiutil attach vlc-2.2.1.dmg && \
cd vlc-2.2.1 && \
cp -R VLC.app Applications
cd ~/motionPlayer
echo "editing VLC settings file..."
curl -O https://raw.githubusercontent.com/edsammy/cyoung/master/vlrc && \
cp vlrc ~/Library/Preferences/org.videolan.vlc
echo "downloading motionPlayer.app"
curl -O https://raw.githubusercontent.com/edsammy/cyoung/master/motionPlayer.app
echo "cleaning up..."
hdiutil detach vlc-2.2.1 && \
rm vlc-2.2.1.dmg
echo "complete!"
