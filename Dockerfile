FROM debian:12

LABEL description="Space Engineers Dedicated Server via Wine + noVNC" \
      org.opencontainers.image.source="https://github.com/MrDKGE/Docker-Space-Engineers" \
      org.opencontainers.image.description="Space Engineers Dedicated Server via Wine + noVNC" \
      org.opencontainers.image.license="GPL-3.0"

# ─────────────────────────────────────────────────────────
#  Environment defaults (override in docker-compose.yml)
# ─────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    RESOLUTION=1280x720x24 \
    WINEPREFIX=/root/.wine \
    WINEARCH=win64 \
    SE_APP_ID=298740 \
    SE_INSTALL_DIR=/opt/spaceengineers

# ─────────────────────────────────────────────────────────
#  1. System packages
#     - xvfb / x11vnc / fluxbox  → virtual display + VNC
#     - supervisor                → process manager
#     - xterm                     → shows install progress
#     - wget / ca-certificates    → downloading files
#     - cabextract / gnupg        → required by winetricks
#     - lib32gcc-s1               → required by SteamCMD
#     - python3                   → required by websockify (noVNC)
# ─────────────────────────────────────────────────────────
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        xvfb x11vnc fluxbox \
        supervisor procps net-tools xterm \
        wget ca-certificates gnupg cabextract \
        python3 \
        lib32gcc-s1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────
#  2. Wine (WineHQ stable from official repository)
# ─────────────────────────────────────────────────────────
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key \
        https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ \
        https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────
#  3. noVNC — browser-based VNC client
#     We need git only for cloning; install → clone → remove.
# ─────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    git clone --depth 1 https://github.com/novnc/noVNC.git        /usr/share/novnc && \
    git clone --depth 1 https://github.com/novnc/websockify.git   /usr/share/novnc/utils/websockify && \
    rm -rf /usr/share/novnc/.git /usr/share/novnc/utils/websockify/.git && \
    apt-get purge -y git && apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    printf '<!DOCTYPE html>\n<html><head>\n  <meta http-equiv="refresh" content="0;url=vnc.html?autoconnect=true&resize=scale">\n</head></html>\n' \
        > /usr/share/novnc/index.html

# ─────────────────────────────────────────────────────────
#  4. SteamCMD (Linux build, used to download SE server)
# ─────────────────────────────────────────────────────────
RUN mkdir -p /opt/steamcmd && \
    wget -qO- https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        | tar xzf - -C /opt/steamcmd && \
    /opt/steamcmd/steamcmd.sh +quit || true

# ─────────────────────────────────────────────────────────
#  5. Winetricks
# ─────────────────────────────────────────────────────────
RUN wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
         -O /usr/local/bin/winetricks && chmod +x /usr/local/bin/winetricks

# ─────────────────────────────────────────────────────────
#  6. Wine prefix — Mono (.NET runtime for SE)
# ─────────────────────────────────────────────────────────
RUN wineboot --init && wineserver --wait && \
    MONO_VER=9.4.0 && \
    wget -q "https://dl.winehq.org/wine/wine-mono/${MONO_VER}/wine-mono-${MONO_VER}-x86.msi" \
         -O /tmp/wine-mono.msi && \
    wine msiexec /i /tmp/wine-mono.msi /qn && \
    wineserver --wait && rm -f /tmp/wine-mono.msi

# Symlink the long Wine AppData path to /opt/se-instance for clean volume mounts
RUN mkdir -p /opt/se-instance && \
    rm -rf /root/.wine/drive_c/users/root/AppData/Roaming/SpaceEngineersDedicated && \
    ln -s /opt/se-instance /root/.wine/drive_c/users/root/AppData/Roaming/SpaceEngineersDedicated

# ─────────────────────────────────────────────────────────
#  7. Winetricks — fonts + Visual C++ 2019 runtime
#     vcrun2019 needs a display, so we start a temporary Xvfb.
# ─────────────────────────────────────────────────────────
RUN winetricks -q corefonts tahoma && wineserver --wait

RUN bash -c 'Xvfb :99 -screen 0 1024x768x24 &' && sleep 2 && \
    DISPLAY=:99 winetricks -q vcrun2019 && \
    wineserver --wait && pkill Xvfb || true

# ─────────────────────────────────────────────────────────
#  8. Font substitutions (makes .NET WinForms UI readable)
# ─────────────────────────────────────────────────────────
RUN for FONT in 'Microsoft Sans Serif' 'Segoe UI' 'MS Shell Dlg' 'MS Shell Dlg 2' 'MS Sans Serif'; do \
        wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes' \
            /v "$FONT" /t REG_SZ /d 'Arial' /f; \
    done && wineserver --wait

# ─────────────────────────────────────────────────────────
#  9. Copy config + entrypoint, fluxbox config
# ─────────────────────────────────────────────────────────
COPY supervisord.conf /etc/supervisord.conf
COPY --chmod=755 startup.sh /startup.sh

# Hide the Fluxbox toolbar (we only need the desktop, not a taskbar)
RUN mkdir -p /root/.fluxbox && \
    printf 'session.screen0.toolbar.visible: false\n' > /root/.fluxbox/init

EXPOSE 5900 6080 27016/udp

CMD ["supervisord", "-c", "/etc/supervisord.conf", "-n"]