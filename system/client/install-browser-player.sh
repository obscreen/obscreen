#!/bin/bash

OWNER=${1:-$USER}
WORKING_DIR=${2:-$HOME}
STUDIO_URL_ARG=${3:-}
BROWSER_ARG=${4:-}

echo "# ==============================="
echo "# Installing Obscreen Player"
echo "# Using user: $OWNER"
echo "# Working Directory: $WORKING_DIR"
echo "# ==============================="

# ============================================================
# User Interaction
# ============================================================

# ------------------
# Default values
# ------------------

# Default studio URL
DEFAULT_STUDIO_URL="http://localhost:5000"
if [ -n "$STUDIO_URL_ARG" ]; then
    DEFAULT_STUDIO_URL="$STUDIO_URL_ARG"
fi

# Default player browser
PLAYER_BROWSER="chromium"
if [ -n "$BROWSER_ARG" ]; then
    PLAYER_BROWSER="$BROWSER_ARG"
fi

if [ "$PLAYER_BROWSER" != "chromium" ] && [ "$PLAYER_BROWSER" != "firefox" ]; then
    echo "Error: Only 'chromium' or 'firefox' are supported as player browsers. You provided: $PLAYER_BROWSER" >&2
    exit 1
fi

obscreen_studio_url=$DEFAULT_STUDIO_URL
disable_interaction=false

# ------------------
# Interaction
# ------------------
for arg in "$@"
do
    if [ "$arg" == "--disable-interaction" ]; then
        disable_interaction=true
        break
    fi
done

if [ "$disable_interaction" = false ]; then
    if [ -t 0 ]; then
        echo ""

        if [ -n "$STUDIO_URL_ARG" ]; then
            obscreen_studio_url="$STUDIO_URL_ARG"
        else
            read -p "Enter Obscreen studio instance URL [default value: ${DEFAULT_STUDIO_URL}]: " user_url
            obscreen_studio_url=${user_url:-$DEFAULT_STUDIO_URL}
        fi
        
        read -p "Do you confirm ${obscreen_studio_url} is a valid Obscreen studio instance? [y/N]: " confirm
        if [[ $confirm == "Y" || $confirm == "y" ]]; then
            echo ""
            echo "Using Obscreen studio instance URL: $obscreen_studio_url"
        else
            echo "Confirmation not received. Please run the script again and enter a valid URL."
            exit 1
        fi


        if [ -n "$BROWSER_ARG" ]; then
            PLAYER_BROWSER="$BROWSER_ARG"
        else
            read -p "Select browser for player: [chromium (default) | firefox]: " browser_choice
            case $browser_choice in
                2)
                    PLAYER_BROWSER="firefox"
                    ;;
                *)
                    PLAYER_BROWSER="chromium"
                    ;;
            esac
        fi

        echo ""
        echo "Using player browser: $PLAYER_BROWSER"
    else
        echo "Interactive input required, but not available. Please run the script in an interactive terminal."
        exit 1
    fi   
else
    # If --disable-interaction is passed, use the default URL without prompting
    echo ""
    echo "Using Obscreen studio instance URL: $DEFAULT_STUDIO_URL"
    echo "Using player browser: $PLAYER_BROWSER"
fi

# ============================================================
# Installation
# ============================================================

echo ""
echo "# Waiting 3 seconds before installation..."
sleep 3

# Set apt confirmation flag for non-interactive installs
APT_CONFIRM=
if [ "$disable_interaction" = true ]; then
    APT_CONFIRM="-y"
fi

# Update and install necessary packages
apt update $APT_CONFIRM

# ------------------
# Browser package(s)
# ------------------
CHROMIUM=""
FIREFOX=""

if [ "$PLAYER_BROWSER" = "chromium" ]; then
  # Detect chromium binary
  if command -v chromium-browser >/dev/null 2>&1; then
    CHROMIUM="chromium-browser"
  elif command -v chromium >/dev/null 2>&1; then
    CHROMIUM="chromium"
  else
    # Attempt to install chromium-browser
    if sudo apt-get install $APT_CONFIRM chromium-browser; then
      CHROMIUM="chromium-browser"
    else
      if sudo apt-get install $APT_CONFIRM chromium; then
        CHROMIUM="chromium"
      fi
    fi

    if [ -z "$CHROMIUM" ]; then
      echo "Error: Chromium could not be installed." >&2
      exit 1
    fi
  fi
else
  # Detect firefox binary
  if command -v firefox-devedition >/dev/null 2>&1; then
    FIREFOX="firefox-devedition"
  elif command -v firefox >/dev/null 2>&1; then
    FIREFOX="firefox"
  else
    # Attempt to install firefox variants
    if sudo apt-get install $APT_CONFIRM firefox-devedition; then
      FIREFOX="firefox"
    else
      if sudo apt-get install $APT_CONFIRM firefox; then
        FIREFOX="firefox"
      fi
    fi

    if [ -z "$FIREFOX" ]; then
      echo "Error: Firefox could not be installed." >&2
      exit 1
    fi
  fi
fi

# ------------------
# Remaining packages
# ------------------
apt install $APT_CONFIRM xinit xserver-xorg x11-xserver-utils xinput unclutter pulseaudio

# ------------------
# Configuration
# ------------------

# Add user to tty, video groups
usermod -aG tty,video,audio,render $OWNER

# Configure X11
touch /etc/X11/Xwrapper.config
grep -qxF "allowed_users=anybody" /etc/X11/Xwrapper.config || echo "allowed_users=anybody" | tee -a /etc/X11/Xwrapper.config
grep -qxF "needs_root_rights=yes" /etc/X11/Xwrapper.config || echo "needs_root_rights=yes" | tee -a /etc/X11/Xwrapper.config
bash -c "cat > /etc/X11/xorg.conf.d/99-pi-video.conf" <<EOF
Section "Device"
    Identifier "Raspberry Pi"
    Driver "modesetting"
    Option "AccelMethod" "glamor"
    Option "DRI" "3"
EndSection

Section "OutputClass"
    Identifier "vc4"
    MatchDriver "vc4"
    Driver "modesetting"
    Option "PrimaryGPU" "true"
EndSection

Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF


# Create the systemd service to start the player in kiosk mode
curl https://raw.githubusercontent.com/obscreen/obscreen/master/system/client/obscreen-player.service  | sed "s# pi # $OWNER #g" | sed "s#/home/pi#$WORKING_DIR#g" | sed "s#=pi#=$OWNER#g" | tee /etc/systemd/system/obscreen-player.service

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable obscreen-player.service
systemctl set-default graphical.target

# Disable display managers
systemctl mask lightdm.service 2>/dev/null || true
systemctl mask wayfire.service 2>/dev/null || true
systemctl mask wayfire@.service 2>/dev/null || true
systemctl mask weston.service 2>/dev/null || true
systemctl mask weston@.service 2>/dev/null || true

# Restart obscreen-player.service
systemctl restart obscreen-player.service

# ============================================================
# Autorun script
# ============================================================

mkdir -p "$WORKING_DIR/obscreen/var/run"

if [ "$PLAYER_BROWSER" = "chromium" ]; then
  mkdir -p "$WORKING_DIR/obscreen/var/run/ext/chromium" 2>/dev/null
  curl https://raw.githubusercontent.com/obscreen/obscreen/master/system/client/autostart-browser-x11-chromium.sh  | sed "s#/home/pi#$WORKING_DIR#g" | sed "s#=pi#=$OWNER#g" | sed "s#chromium-browser#$CHROMIUM#g" | sed "s#http://localhost:5000#$obscreen_studio_url#g" | tee "$WORKING_DIR/obscreen/var/run/play"
  curl https://raw.githubusercontent.com/obscreen/obscreen/master/extensions/chromium/ext/manifest.json | tee "$WORKING_DIR/obscreen/var/run/ext/chromium/manifest.json"
  curl https://raw.githubusercontent.com/obscreen/obscreen/master/extensions/chromium/ext/background.js | tee "$WORKING_DIR/obscreen/var/run/ext/chromium/background.js"
  curl https://raw.githubusercontent.com/obscreen/obscreen/master/extensions/chromium/ext/rules.json | tee "$WORKING_DIR/obscreen/var/run/ext/chromium/rules.json"
else
  mkdir -p "$WORKING_DIR/obscreen/var/run/ext/firefox" 2>/dev/null
  curl https://raw.githubusercontent.com/obscreen/obscreen/master/system/client/autostart-browser-x11-firefox.sh | sed "s#/home/pi#$WORKING_DIR#g" | sed "s#=pi#=$OWNER#g" | sed "s#http://localhost:5000#$obscreen_studio_url#g" | tee "$WORKING_DIR/obscreen/var/run/play"
  curl https://raw.githubusercontent.com/obscreen/obscreen/master/extensions/firefox/ext.xpi -o "$WORKING_DIR/obscreen/var/run/ext/firefox/ext.xpi" 2>/dev/null
fi

chmod +x "$WORKING_DIR/obscreen/var/run/play"
chown -R $OWNER:$OWNER "$WORKING_DIR/obscreen"

# ============================================================
# Start
# ============================================================

# Finally, restart player service
systemctl restart obscreen-player.service
