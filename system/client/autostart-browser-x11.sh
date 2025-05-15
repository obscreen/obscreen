#!/bin/bash

# Configuration
## Main Obscreen Studio instance URL (could be a specific playlist /use/[playlist-id] or let obscreen manage playlist routing with /
STUDIO_URL=http://localhost:5000
## e.g. 1920x1080 - Force specific resolution (supported list available with command `DISPLAY=:0 xrandr`)
SCREEN_RESOLUTION=auto
## Values are either: normal (0°), right (90°), inverted (180°), left (270°)
SCREEN_ROTATE=normal

# Client metadata
## Network
CLIENT_HOSTNAME=
## Icon
CLIENT_ICON=auto # any font-awesome icon name (i.e. fa-desktop, fa-laptop, fa-tablet, fa-mobile, fa-tablet-alt, fa-mobile-alt)
## Positioning
### 1. Precise positioning
CLIENT_LONGITUDE=
CLIENT_LATITUDE=
### 2. Structured address-based positioning
CLIENT_STREET=
CLIENT_CITY=
CLIENT_STATE=
CLIENT_COUNTRY=
CLIENT_POSTAL_CODE=
### 3. Query address-based positioning (i.e. "1600 Pennsylvania Avenue NW, Washington, DC 20500")
CLIENT_ADDRESS_QUERY=

# ================================================================================================================================================

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

# Build the URL with client parameters
### Dynamically append all CLIENT_ parameters to URL when not empty
STUDIO_URL="${STUDIO_URL}?"
for var in $(compgen -v | grep "^CLIENT_"); do
    # Get the parameter name by removing CLIENT_ prefix and converting to lowercase
    param=$(echo ${var#CLIENT_} | tr '[:upper:]' '[:lower:]')
    value=${!var}
    
    # Skip empty values and "auto" for icon
    if [ ! -z "$value" ] && [ "$value" != "auto" ]; then
        STUDIO_URL="${STUDIO_URL}${param}=${value}&"
    fi
done
for var in $(compgen -v | grep "^SCREEN_"); do
    param=$(echo ${var#SCREEN_} | tr '[:upper:]' '[:lower:]')
    value=${!var}
    if [ ! -z "$value" ] && [ "$value" != "auto" ]; then
        STUDIO_URL="${STUDIO_URL}${param}=${value}&"
    fi
done
# Remove trailing '&' or '?' if present
STUDIO_URL=$(echo $STUDIO_URL | sed 's/[?&]$//')
###

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

