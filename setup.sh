#!/bin/bash

cd ~
echo "creating directories..."
mkdir motionPlayer && cd motionPlayer
mkdir videos
echo "checking if VLC player is installed..."
if [ -a /Applications/VLC.app ]
    then
    echo "VLC already installed, skipping download..."
else
    echo "downloading VLC media player..."
    curl -O http://mirror.de.leaseweb.net/videolan/vlc/2.2.1/macosx/vlc-2.2.1.dmg && \
    hdiutil attach -quiet vlc-2.2.1.dmg && \
    cd /Volumes/vlc-2.2.1 && \
    cp -R VLC.app Applications
fi
cd ~/motionPlayer
echo "editing VLC settings file..."
curl -O --silent https://raw.githubusercontent.com/edsammy/cyoung/master/vlcrc && \
cp vlcrc ~/Library/Preferences/org.videolan.vlc
echo "downloading motionPlayer.app"
curl -O --silent https://raw.githubusercontent.com/edsammy/cyoung/master/motionPlayer.app
echo "cleaning up..."
cd /Volumes
hdiutil detach vlc-2.2.1 && \
cd ~/motionPlayer && \
rm vlc-2.2.1.dmg
echo "complete!"
