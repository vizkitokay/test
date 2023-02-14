# This Dockerfile is used to build an headles vnc image based on Ubuntu

#FROM ubuntu:latest
FROM x11docker/xfce:latest

MAINTAINER Cute Google "admin@google.com"
ENV REFRESHED_AT 2023-02-14-12:20
ENV VERSION 1.0

LABEL io.k8s.description="Headless VNC Container with Xfce window manager" \
      io.k8s.display-name="Headless VNC Container based on Ubuntu" \
      io.openshift.expose-services="6901:http,5901:xvnc" \
      io.openshift.tags="vnc, ubuntu, xfce" \
      io.openshift.non-scalable=true

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

USER root
### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=meenscute \
    VNC_VIEW_ONLY=false \
    LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'


WORKDIR $HOME

RUN apt-get update

RUN apt-get install -y apt-utils locales language-pack-en language-pack-en-base ; update-locale 

RUN apt-get install -y \    
    libnss-wrapper \
    gettext \
    xfce4 \
    xfce4-terminal \
    xterm 


#oooooooooooooooooooooooooooooooooooooooooooooo


# cleanapt script for use after apt-get
RUN echo '#! /bin/sh\n\
env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y\n\
apt-get clean\n\
find /var/lib/apt/lists -type f -delete\n\
find /var/cache -type f -delete\n\
find /var/log -type f -delete\n\
exit 0\n\
' > /cleanapt && chmod +x /cleanapt

RUN . /etc/os-release && \
    echo "deb http://deb.debian.org/debian $VERSION_CODENAME contrib non-free" >> /etc/apt/sources.list && \
    env DEBIAN_FRONTEND=noninteractive dpkg --add-architecture i386 && \
    apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        fonts-wine \
        locales \
        ttf-mscorefonts-installer \
        wget \
        winbind \
        wine \
        winetricks && \
    /cleanapt

RUN mkdir -p /usr/share/wine/gecko && \
    cd /usr/share/wine/gecko && \
    wget https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi && \
    wget https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86_64.msi

RUN mkdir -p /usr/share/wine/mono && \
    cd /usr/share/wine/mono && \
    wget https://dl.winehq.org/wine/wine-mono/4.9.4/wine-mono-4.9.4.msi

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        gettext \
        gnome-icon-theme \
        playonlinux \
        q4wine \
        xterm && \
    /cleanapt

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libpulse0 \
        libxv1 \
        mesa-utils \
        mesa-utils-extra \
        pasystray \
        pavucontrol && \
    /cleanapt

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xfwm4 && \
    /cleanapt && \
    mkdir -p /etc/skel/.config/lxsession/LXDE && \
    echo '[Session]\n\
window_manager=xfwm4\n\
' >/etc/skel/.config/lxsession/LXDE/desktop.conf

# Enable this for chinese, japanese and korean fonts in wine
#RUN winetricks -q cjkfonts

# create desktop icons
#
RUN mkdir -p /etc/skel/Desktop && \
echo '#! /bin/bash \n\
datei="/etc/skel/Desktop/$(echo "$1" | LC_ALL=C sed -e "s/[^a-zA-Z0-9,.-]/_/g" ).desktop" \n\
echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=$1\n\
Exec=$2\n\
Icon=$3\n\
" > $datei \n\
chmod +x $datei \n\
' >/usr/local/bin/createicon && chmod +x /usr/local/bin/createicon && \
\
createicon "PlayOnLinux"        "playonlinux"       playonlinux && \
createicon "Q4wine"             "q4wine"            q4wine && \
createicon "Internet Explorer"  "wine iexplore"     applications-internet && \
createicon "Console"            "wineconsole"       utilities-terminal && \
createicon "File Explorer"      "wine explorer"     folder && \
createicon "Notepad"            "wine notepad"      wine-notepad && \
createicon "Wordpad"            "wine wordpad"      accessories-text-editor && \
createicon "winecfg"            "winecfg"           wine-winecfg && \
createicon "WineFile"           "winefile"          folder-wine && \
createicon "Mines"              "wine winemine"     face-cool && \
createicon "winetricks"         "winetricks -gui"   wine && \
createicon "Registry Editor"    "regedit"           preferences-system && \
createicon "UnInstaller"        "wine uninstaller"  wine-uninstaller && \
createicon "Taskmanager"        "wine taskmgr"      utilities-system-monitor && \
createicon "Control Panel"      "wine control"      preferences-system && \
createicon "OleView"            "wine oleview"      preferences-system && \
createicon "CJK fonts installer chinese japanese korean"  "xterm -e \"winetricks cjkfonts\""  font

#------------------------------------------------------------

### noVNC needs python2 and ubuntu docker image is not providing any default python
RUN test -e /usr/bin/python && rm -f /usr/bin/python ; ln -s /usr/bin/python3 /usr/bin/python

RUN apt-get purge -y pm-utils xscreensaver* && \
    apt-get -y clean

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN mkdir -p $NO_VNC_HOME/utils/websockify && \
    wget -qO- https://netcologne.dl.sourceforge.net/project/tigervnc/stable/1.10.1/tigervnc-1.10.1.x86_64.tar.gz | tar xz --strip 1 -C / && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.2.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME && \
    wget -qO- https://github.com/novnc/websockify/archive/v0.10.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify && \
    chmod +x -v $NO_VNC_HOME/utils/*.sh && \
    cp -f /headless/noVNC/vnc.html /headless/noVNC/index.html

### inject files
ADD ./src/xfce/ $HOME/
ADD ./src/scripts $STARTUPDIR

### configure startup and set perms
RUN echo "CHROMIUM_FLAGS='--no-sandbox --start-maximized --user-data-dir'" > $HOME/.chromium-browser.init && \
    /bin/sed -i '1 a. /headless/.bashrc' /etc/xdg/xfce4/xinitrc && \
    find $STARTUPDIR $HOME -name '*.sh' -exec chmod a+x {} + && \
    find $STARTUPDIR $HOME -name '*.desktop' -exec chmod a+x {} + && \
    chgrp -R 0 $STARTUPDIR $HOME && \
    chmod -R a+rw $STARTUPDIR $HOME && \
    find $STARTUPDIR $HOME -type d -exec chmod a+x {} + && \
    echo LANG=en_US.UTF-8 > /etc/default/locale && \
    locale-gen en_US.UTF-8

#--------------------------------------------
# We add a simple user with sudo rights
ENV     USR=user
ARG     USR_UID=${USER_UID:-1000}
ARG     USR_GID=${USER_GID:-1000}

RUN     \
        echo "Add simple user" >&2                                                      \
        && groupadd --gid ${USR_GID} ${USR}                                             \
        && useradd --uid ${USR_UID} --create-home --gid ${USR} --shell /bin/bash ${USR} \
        && echo "${USR}:${USR}01" | chpasswd                                            \
        && echo ${USR}'     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers                     \
        && echo "Add simple user OK" >&2

# We change user
USER    ${USR}
WORKDIR /home/${USR}

#USER    1000
#--------------------------------------------

ENTRYPOINT ["/dockerstartup/desktop_startup.sh"]
CMD ["--wait"]



