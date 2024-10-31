#!/bin/bash

# Configuration
## Main Obscreen Studio instance URL (could be a specific playlist /use/[playlist-id] or let obscreen manage playlist routing with /
STUDIO_URL=http://localhost:5000
## e.g. 1920x1080 - Force specific resolution (supported list available with command `DISPLAY=:0 xrandr`)
SCREEN_RESOLUTION=auto
## Values are either: normal (0°), right (90°), inverted (180°), left (270°)
SCREEN_ROTATE=normal

# Disable screensaver and DPMS
xset s off
xset -dpms
xset s noblank

# Start unclutter to hide the mouse cursor
unclutter -display :0 -noevents -grab &

# Modify Chromium preferences to avoid restore messages
CHROMIUM_DIRECTORY=$HOME/.config/chromium
mkdir -p $CHROMIUM_DIRECTORY/Default 2>/dev/null
touch /$CHROMIUM_DIRECTORY/Default/Preferences
sed -i 's/"exited_cleanly": false/"exited_cleanly": true/' $CHROMIUM_DIRECTORY/Default/Preferences

FIRST_CONNECTED_SCREEN=$(xrandr | grep " connected" | awk '{print $1}' | head -n 1)

# Resolution setup
if [ "$SCREEN_RESOLUTION" != "auto" ]; then
    xrandr --output $FIRST_CONNECTED_SCREEN --mode $SCREEN_RESOLUTION
fi

xrandr --output $FIRST_CONNECTED_SCREEN --rotate $SCREEN_ROTATE

RESOLUTION=$(DISPLAY=:0 xrandr | grep '*' | awk '{print $1}')
WIDTH=$(echo $RESOLUTION | cut -d 'x' -f 1)
HEIGHT=$(echo $RESOLUTION | cut -d 'x' -f 2)

# Start Chromium in kiosk mode
chromium-browser \
  --disk-cache-size=2147483647 \
  --disable-features=Translate \
  --ignore-certificate-errors \
  --disable-web-security \
  --disable-restore-session-state \
  --autoplay-policy=no-user-gesture-required \
  --start-maximized \
  --allow-running-insecure-content \
  --remember-cert-error-decisions \
  --noerrdialogs \
  --kiosk \
  --user-data-dir=${CHROMIUM_DIRECTORY} \
  --no-sandbox \
  --window-position=0,0 \
  --load-extension=/home/pi/obscreen/var/run/ext \
  --window-size=${WIDTH},${HEIGHT} \
  --display=:0 \
  ${STUDIO_URL}

