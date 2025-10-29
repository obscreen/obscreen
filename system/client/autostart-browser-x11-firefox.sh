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

# Firefox profile directory and preferences
FIREFOX_PROFILE_DIR=$HOME/.config/obscreen-firefox
mkdir -p "$FIREFOX_PROFILE_DIR" 2>/dev/null
USER_JS="$FIREFOX_PROFILE_DIR/user.js"

cat > "$USER_JS" <<'EOF'
user_pref("dom.block_external_protocol_in_iframes", false);
user_pref("dom.webnotifications.allowcrossoriginiframe", true);
user_pref("layout.throttle_in_process_iframes", false);
user_pref("network.http.referer.XOriginPolicy", 0);
user_pref("network.http.referer.XOriginTrimmingPolicy", 0);
user_pref("browser.cache.disk.capacity", 2147483647);
user_pref("security.enterprise_roots.enabled", true);
user_pref("security.OCSP.enabled", false);
user_pref("dom.media.autoplay-policy-detection.enable", false);
user_pref("media.autoplay.blocking_policy", 0);
user_pref("media.autoplay.default", 0);
user_pref("media.block-autoplay-until-in-foreground", false);
user_pref("network.cookie.sameSite.noneRequiresSecure", false);
user_pref("network.cookie.sameSite.schemeful", false);
user_pref("network.cookie.sameSite.laxByDefault", false);
user_pref("network.cookie.sameSite.crossSiteIframeSetCheck", false);
user_pref("media.devices.insecure.enabled", true);
user_pref("security.mixed_content.block_active_content", false);
user_pref("security.mixed_content.block_display_content", false);
user_pref("security.mixed_content.block_object_subrequest", false);
user_pref("security.insecure_field_warning.contextual.enabled", false);
user_pref("security.certerrors.permanentOverride", false);
user_pref("network.stricttransportsecurity.preloadlist", false);
user_pref("security.enterprise_roots.enabled", true);
user_pref("network.http.referer.defaultPolicy.pbmode", 0);
user_pref("network.http.referer.defaultPolicy.trackers", 0);
user_pref("network.http.referer.defaultPolicy.trackers.pbmode", 0);
user_pref("network.http.referer.disallowCrossSiteRelaxingDefault", false);
user_pref("network.http.referer.disallowCrossSiteRelaxingDefault.pbmode", false);
user_pref("network.http.referer.disallowCrossSiteRelaxingDefault.pbmode.top_navigation", false);
user_pref("network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation", false);
user_pref("security.fileuri.strict_origin_policy", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("dom.block_download_insecure", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.homepage", "about:blank");
user_pref("xpinstall.signatures.required", false);
user_pref("extensions.autoDisableScopes", 0);
user_pref("extensions.enabledScopes", 15);
user_pref("extensions.install.requireBuiltInCerts", false);
user_pref("extensions.logging.enabled", true);
user_pref("browser.rights.3.shown", true);
user_pref("rkiosk.navbar", false);
user_pref("browser.fullscreen.autohide", true);
user_pref("zoom.minPercent", 100);
user_pref("zoom.maxPercent", 100);
user_pref("zoom.defaultPercent", 100);
EOF

# Ensure extensions directory exists and install extension if it exists
FIREFOX_EXT_FILE="/home/pi/obscreen/var/run/ext/firefox/ext.xpi"
FIREFOX_EXT_DIR="$FIREFOX_PROFILE_DIR/extensions"
mkdir -p "$FIREFOX_EXT_DIR" 2>/dev/null
cp -f "$FIREFOX_EXT_FILE" "$FIREFOX_EXT_DIR/{a6afa2be-9b78-4dba-9dda-d89e52b13b7d}.xpi" 2>/dev/null

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

# Detect firefox binary
FIREFOX_BIN=""
if command -v firefox-devedition >/dev/null 2>&1; then
  FIREFOX_BIN="firefox-devedition"
elif command -v firefox >/dev/null 2>&1; then
  FIREFOX_BIN="firefox"
else
  echo "Firefox binary not found." >&2
  echo "Please install firefox-devedition or firefox." >&2
  exit 1
fi

# Start Firefox in kiosk mode
"$FIREFOX_BIN" \
  --no-remote \
  --kiosk \
  --profile "$FIREFOX_PROFILE_DIR" \
  --width ${WIDTH} \
  --height ${HEIGHT} \
  ${STUDIO_URL}


