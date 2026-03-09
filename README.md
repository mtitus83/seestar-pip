# Seestar RTSP Overlay Monitor

This project provides a **persistent RTSP overlay window** for the ZWO Seestar camera feed using **mpv**.
It is designed to run on a Raspberry Pi (or Linux desktop) alongside applications such as **Stellarium**, providing a small always-on-top video preview of the telescope camera.

The system automatically:

* Starts the overlay window
* Waits for the RTSP stream to become available
* Connects to the stream when detected
* Monitors the stream every 15 seconds
* Automatically reconnects if the stream drops

This makes the overlay resilient to:

* Seestar reboots
* WiFi interruptions
* RTSP server restarts

---

# Architecture

The system uses three main components:

```
systemd user service
        ↓
monitor script
        ↓
mpv player (with IPC socket)
```

### Flow

```
login
 ↓
systemd user service starts
 ↓
60 second delay
 ↓
monitor script launches mpv
 ↓
mpv creates overlay window
 ↓
script detects RTSP stream
 ↓
script instructs mpv to load the stream
 ↓
video appears in overlay
```

If the stream disappears, the script detects this and reloads it.

---

# Files

## `seestar-monitor.sh`

Main monitoring script responsible for:

* launching mpv
* detecting RTSP availability
* reconnecting when needed

It communicates with mpv using the **mpv IPC socket**.

---

## `seestar-pip.service`

A **systemd user service** that starts the monitor script automatically when the user logs in.

Features:

* delayed startup (60 seconds)
* automatic restart if the script crashes
* integrated logging through `journalctl`

---

## `mpv.conf`

Contains the **mpv profile** used for the overlay window.

Example profile:

```
[seestar-pip]
ontop
no-border
geometry=426x240-20-20
vo=x11
rtsp-transport=tcp
force-window=yes
idle=yes
no-osc
msg-level=all=no
input-ipc-server=/tmp/mpv-seestar
hwdec=no
cache=no
```

This profile configures:

* a borderless window
* bottom-right positioning
* always-on-top behavior
* low latency streaming
* IPC control socket

---

# Requirements

Packages required:

```
mpv
socat
netcat-openbsd
```

Install them with:

```
sudo apt install mpv socat netcat-openbsd
```

---

# Installation

Clone the repository:

```
git clone <repo-url>
cd <repo>
```

Make the script executable:

```
chmod +x seestar-monitor.sh
```

Copy the systemd service file:

```
mkdir -p ~/.config/systemd/user
cp seestar-pip.service ~/.config/systemd/user/
```

Reload systemd user services:

```
systemctl --user daemon-reload
```

Enable the service:

```
systemctl --user enable seestar-pip
```

Start it immediately:

```
systemctl --user start seestar-pip
```

---

# Logs and Debugging

View the service status:

```
systemctl --user status seestar-pip
```

View live logs:

```
journalctl --user -u seestar-pip -f
```

Typical log messages include:

```
Starting mpv...
Stream detected. Connecting...
Reloading stream...
Stream lost.
```

---

# Customization

You may adjust the RTSP source inside the script:

```
STREAM="rtsp://10.220.29.70:4555/stream"
```

Overlay size and position can be modified in the `mpv` profile:

```
geometry=426x240-20-20
```

Format:

```
WIDTHxHEIGHT-XOFFSET-YOFFSET
```

---

# Notes

* This project uses a **systemd user service**, not a system service, because mpv must run inside the user's graphical session.
* The script uses the **mpv IPC interface** to control playback without restarting the player.

---

# License

MIT License (or whatever license your repo uses).

