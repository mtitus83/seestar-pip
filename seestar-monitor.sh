#!/bin/bash

STREAM="rtsp://10.220.29.70:4555/stream"
SOCKET="/tmp/mpv-seestar"

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

show_wait_message() {
    echo '{ "command": ["show-text", "Waiting for Seestar...", 4000] }' \
        | socat - "$SOCKET"
}

reload_stream() {
    echo "Reloading stream..."

    show_wait_message

    echo '{ "command": ["stop"] }' | socat - "$SOCKET"
    sleep 1

    echo '{ "command": ["loadfile", "'"$STREAM"'"] }' | socat - "$SOCKET"
    sleep 1

    echo '{ "command": ["set_property", "pause", false] }' | socat - "$SOCKET"
}

get_playback_time() {
    echo '{ "command": ["get_property", "playback-time"] }' \
        | socat - "$SOCKET" | jq -r '.data // 0'
}

start_mpv
wait_for_socket

reload_stream

LAST_TIME=0
STALL_COUNT=0

while true; do

    CURRENT_TIME=$(get_playback_time)

    if [ "$CURRENT_TIME" = "null" ] || [ "$CURRENT_TIME" = "0" ]; then
        ((STALL_COUNT++))
    elif (( $(echo "$CURRENT_TIME > $LAST_TIME" | bc -l) )); then
        STALL_COUNT=0
        LAST_TIME=$CURRENT_TIME
    else
        ((STALL_COUNT++))
    fi

    if [ "$STALL_COUNT" -ge 3 ]; then
        echo "Stream stalled. Reconnecting..."
        reload_stream
        STALL_COUNT=0
    fi

    sleep 5

done
