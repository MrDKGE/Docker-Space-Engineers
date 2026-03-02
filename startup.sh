#!/bin/bash
# ─────────────────────────────────────────────────────────
#  startup.sh — Space Engineers Dedicated Server entrypoint
#
#  This script is called by supervisord inside the container.
#  It handles:
#    1. First-time install via SteamCMD (with visible progress)
#    2. Launching the server (GUI or headless console mode)
# ─────────────────────────────────────────────────────────
set -euo pipefail

# ── Configuration (set via environment or defaults) ──
SE_DIR="${SE_INSTALL_DIR:-/opt/spaceengineers}"
SE_EXE="${SE_DIR}/DedicatedServer64/SpaceEngineersDedicated.exe"
SE_APP_ID="${SE_APP_ID:-298740}"
GUI="${GUI:-true}"
MAX_RETRIES=5

# Wait for the virtual display (Xvfb) to be ready before launching anything
sleep 3

# ─────────────────────────────────────────────────────────
#  First-time install
#
#  If the SE executable doesn't exist yet, download it via
#  SteamCMD. Progress is displayed in a visible xterm window
#  on the noVNC desktop so you can watch from your browser.
#  After the first run, SE manages its own updates through
#  the built-in updater in the server GUI.
# ─────────────────────────────────────────────────────────
if [[ ! -f "$SE_EXE" ]]; then
    echo "Space Engineers not found – installing via SteamCMD..."
    LOGFILE=/tmp/steamcmd_install.log
    : > "$LOGFILE"
    xterm -T "Installing Space Engineers..." -geometry 120x30+50+50 -e "tail -f $LOGFILE" &
    XTERM_PID=$!

    for ((i=1; i<=MAX_RETRIES; i++)); do
        /opt/steamcmd/steamcmd.sh \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir "$SE_DIR" \
            +login anonymous \
            +app_update "$SE_APP_ID" validate \
            +quit 2>&1 | tee -a "$LOGFILE" && break
        echo "Attempt $i/$MAX_RETRIES failed, retrying in 10 s..." | tee -a "$LOGFILE"
        sleep 10
    done

    echo "" | tee -a "$LOGFILE"
    echo "=== Installation finished. This window will close in 10 seconds ===" | tee -a "$LOGFILE"
    sleep 10
    kill "$XTERM_PID" 2>/dev/null || true
    rm -f "$LOGFILE"

    if [[ ! -f "$SE_EXE" ]]; then
        xterm -T "ERROR" -hold -geometry 80x10+100+100 \
            -e "echo 'Install failed after $MAX_RETRIES attempts.'; echo 'Check network / Steam and restart the container.'" &
        exec sleep infinity
    fi
fi

# ─────────────────────────────────────────────────────────
#  Launch the server
#
#  GUI=true  → normal GUI mode, configure via noVNC
#  GUI=false → headless console mode (-console flag)
#
# ─────────────────────────────────────────────────────────
echo "Starting Space Engineers Dedicated Server..."
cd "${SE_DIR}/DedicatedServer64"

case "${GUI,,}" in
    1|true|yes|on)
        echo "GUI mode: launching server with graphical interface"
        exec wine "$SE_EXE"
        ;;
    *)
        echo "Console mode: launching server headless (-console)"
        exec wine "$SE_EXE" -console
        ;;
esac
