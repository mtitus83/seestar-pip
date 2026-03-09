#!/bin/bash

STREAM="rtsp://10.220.29.70:4555/stream"
SOCKET="/tmp/mpv-seestar"
HOST="10.220.29.70"
PORT="4555"

export DISPLAY=:0

start_mpv() {
    if ! pgrep -x mpv >/dev/null; then
        echo "Starting mpv..."
        mpv --profile=seestar-overlay &
    fi
}

wait_for_socket() {
    while [ ! -S "$SOCKET" ]; do
        sleep 0.5
    done
}

reload_stream() {
    echo "Reloading stream..."

    echo '{ "command": ["stop"] }' | socat - "$SOCKET"
    sleep 1

    echo '{ "command": ["loadfile", "'"$STREAM"'"] }' | socat - "$SOCKET"
    sleep 1

    echo '{ "command": ["set_property", "pause", false] }' | socat - "$SOCKET"
}

start_mpv
wait_for_socket

STREAM_ACTIVE=0

while true; do

    if nc -z "$HOST" "$PORT" 2>/dev/null; then
        if [ "$STREAM_ACTIVE" -eq 0 ]; then
            echo "Stream detected. Connecting..."
            reload_stream
            STREAM_ACTIVE=1
        fi
    else
        if [ "$STREAM_ACTIVE" -eq 1 ]; then
            echo "Stream lost."
            STREAM_ACTIVE=0
        fi
    fi

    sleep 15

done
