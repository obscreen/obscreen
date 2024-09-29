# <img src="https://github.com/jr-k/obscreen/blob/master/docs/img/obscreen.png" width="22"> Obscreen - Headless run on any server

> #### 👈 [back to readme](/README.md)

#### 🔵 You just want a slideshow manager, and you'll deal with screen and browser yourself ? You're in the right place.


---
## 📡 Run the Server Studio instance

<details closed>
<summary><h3>Using docker run</h3></summary>

```bash
# (Optional) Install docker if needed
curl -sSL get.docker.com | sh && sudo usermod -aG docker $(whoami) && logout 
# ....then login again
```

---

```bash
# Prepare application data file tree
cd ~ && mkdir -p obscreen/data/db obscreen/data/uploads && cd obscreen

# Run the Docker container
docker run --restart=always --name obscreen --pull=always \
  -e DEBUG=false \
  -e PORT=5000 \
  -e SECRET_KEY=ANY_SECRET_KEY_HERE \
  -p 5000:5000 \
  -v ./data/db:/app/data/db \
  -v ./data/uploads:/app/data/uploads \
  jierka/obscreen:latest
```

---

</details>

<details closed>
<summary><h3>Using docker compose</h3></summary>

```bash
# Prepare application data file tree
cd ~ && mkdir -p obscreen/data/db obscreen/data/uploads && cd obscreen

# Download docker-compose.yml
curl https://raw.githubusercontent.com/jr-k/obscreen/master/docker-compose.yml > docker-compose.yml

# Run
docker compose up --detach --pull=always
```

---

</details>

<details closed>
<summary><h3>System-wide</h3></summary>

#### Install
- Install Server Studio by executing following script

##### Linux
```bash
curl -fsSL https://raw.githubusercontent.com/jr-k/obscreen/master/system/server/install-server-studio.sh -o /tmp/install-server-studio.sh && chmod +x /tmp/install-server-studio.sh && sudo /bin/bash /tmp/install-server-studio.sh $USER $HOME
sudo reboot
```
##### Windows & MacOS
```bash
git clone https://github.com/jr-k/obscreen.git
cd obscreen
python3 -m venv venv
source ./venv/bin/activate
pip install .
cp .env.dist .env
```

#### Configure
- Server configuration is editable in `.env` file.
- Application configuration will be available at `http://localhost:5000/settings` page after run.
- Check logs with `journalctl -u obscreen-studio -f` 


---

</details>


## 👌 Usage
- Page which plays slideshow is reachable at `http://localhost:5000`
- Slideshow manager is reachable at `http://localhost:5000/manage`


## 📺 Run the player instance

<details closed>
<summary><h3>Autorun for a RaspberryPi</h3></summary>

#### How to install
- Install player autorun by executing following script (will install chromium, x11, pulseaudio and obscreen-player systemd service)
```bash
curl -fsSL https://raw.githubusercontent.com/jr-k/obscreen/master/system/client/install-client-player.sh -o /tmp/install-client-player.sh && chmod +x /tmp/install-client-player.sh && sudo /bin/bash /tmp/install-client-player.sh $USER $HOME
sudo reboot
```

#### How to restart
1. Just use systemctl `sudo systemctl restart obscreen-player.service`


---

</details>

<details closed>
<summary><h3>Manually on any device capable of running chromium</h3></summary>

When you run the browser yourself, don't forget to use these flags for chromium browser:
```bash
# chromium or chromium-browser or even chrome
# replace http://localhost:5000 with your Server Studio instance url
chromium \
  --disk-cache-size=2147483648 \
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
  --incognito \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --display=:0 \
  http://localhost:5000
```

---

</details>


## 📎 Additional


<details closed>
<summary><h3>How to upgrade Server Studio instance</h3></summary>

#### with docker run
- Just add `--pull=always` to your `docker run ...` command, you'll get the latest version automatically.
#### or with docker compose
- Just add `--pull=always` to your `docker compose up ...` command, you'll get the latest version automatically.
#### or system-wide
- Using Git Updater plugin
- Or by executing following script
```bash
cd ~/obscreen
git pull
source ./venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart obscreen-studio.service
```

---

</details>
