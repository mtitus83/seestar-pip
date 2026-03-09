# seestar-pip

**seestar-pip** provides a persistent **picture-in-picture RTSP overlay** for the ZWO Seestar camera feed using **mpv**.

It is designed for telescope control setups where applications like **Stellarium** are used alongside a small live camera preview of the telescope.

The system automatically:

* launches a small always-on-top overlay window
* connects to the Seestar RTSP stream
* detects stalled streams
* reconnects automatically
* recovers from Seestar disconnects and reconnects

The overlay behaves like a **persistent HUD camera feed**.

---

# Features

* Always-on-top **picture-in-picture overlay**
* Automatic **RTSP reconnection**
* Detects **stalled video streams**
* Recovers from:

  * Seestar WiFi reconnects
  * exiting and re-entering Scenery Mode
  * RTSP stream freezes
* Minimal latency
* Automatically starts at login

---

# Architecture

```text
systemd user service
        ↓
seestar-monitor.sh
        ↓
mpv player
        ↓
RTSP stream
```

Startup flow:

```text
login
 ↓
systemd user service starts
 ↓
60 second delay
 ↓
monitor script starts mpv
 ↓
overlay window appears
 ↓
script connects to RTSP stream
 ↓
video plays
```

If the stream stalls:

```text
video stalls
 ↓
script detects playback-time freeze
 ↓
overlay shows "Waiting for Seestar..."
 ↓
stream reloads automatically
```

---

# Repository Files

## `seestar-monitor.sh`

Main monitoring script.

Responsibilities:

* launches mpv
* monitors RTSP playback state
* detects stalled streams
* reconnects the stream when necessary
* displays overlay status messages

It communicates with mpv using the **mpv IPC socket**.

---

## `seestar-pip.service`

A **systemd user service** that launches the monitor script automatically when the user logs in.

Features:

* delayed startup (60 seconds)
* automatic restart if the script exits
* integrates with `journalctl` logging

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

* borderless overlay window
* bottom-right screen placement
* IPC control socket
* low latency streaming

---

# Requirements

Required packages:

```
mpv
socat
jq
bc
netcat-openbsd
```

Install with:

```
sudo apt install mpv socat jq bc netcat-openbsd
```

---

# Installation

Clone the repository:

```
git clone <repo-url>
cd seestar-pip
```

Make the monitor script executable:

```
chmod +x seestar-monitor.sh
```

Install the systemd user service:

```
mkdir -p ~/.config/systemd/user
cp seestar-pip.service ~/.config/systemd/user/
```

Reload systemd services:

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

Check service status:

```
systemctl --user status seestar-pip
```

View live logs:

```
journalctl --user -u seestar-pip -f
```

Typical log messages:

```
Starting mpv...
Reloading stream...
Stream stalled. Reconnecting...
```

---

# Configuration

RTSP stream location can be modified inside the script:

```
STREAM="rtsp://10.220.29.70:4555/stream"
```

Overlay window size and position are controlled in the mpv profile:

```
geometry=426x240-20-20
```

Format:

```
WIDTHxHEIGHT-XOFFSET-YOFFSET
```

Example:

```
426x240-20-20
```

Positions the overlay in the **bottom-right corner**.

---

# Notes

* This project uses a **systemd user service** rather than a system service so that mpv can run inside the user's graphical session.
* The monitor script uses **mpv's IPC interface** to control playback without restarting the player.
* The system detects **frozen video streams**, not just dropped network connections.

---

# License

MIT License (or whichever license your repository uses).

