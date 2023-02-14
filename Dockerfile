# This Dockerfile is used to build an headles vnc image based on Ubuntu

FROM ubuntu:latest

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

#------------- edit ------------------

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get -y install python3 python-is-python3 python3-pip python3-numpy software-properties-common tzdata apt-utils sudo x11vnc xvfb fluxbox xdotool wget tar curl supervisor net-tools gnupg2

RUN wget -O - https://dl.winehq.org/wine-builds/winehq.key | apt-key add -  && \
    echo 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' |tee /etc/apt/sources.list.d/winehq.list
    
RUN apt-get update && apt-get -y install winehq-stable

# Install and unpack Wine-mono as shared install
RUN mkdir -p /usr/share/wine/mono && wget -O /usr/share/wine/mono/wine-mono-7.4.0-x86.tar.xz https://dl.winehq.org/wine/wine-mono/7.4.0/wine-mono-7.4.0-x86.tar.xz
RUN cd /usr/share/wine/mono/ && tar -xJf wine-mono-7.4.0-x86.tar.xz

# Install and unpack Wine-gecko (for html .net component) as shared install
RUN mkdir -p /usr/share/wine/gecko && wget -O /usr/share/wine/gecko/wine-gecko-2.47.3-x86.tar.xz https://dl.winehq.org/wine/wine-gecko/2.47.3/wine-gecko-2.47.3-x86.tar.xz
RUN cd /usr/share/wine/gecko && tar xJf wine-gecko-2.47.3-x86.tar.xz

# Install winetrick
RUN mkdir -p /usr/bin && wget -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks

#------------- edit -----------------
WORKDIR $HOME

RUN apt-get update

RUN apt-get install -y apt-utils locales language-pack-en language-pack-en-base ; update-locale 

RUN apt-get install -y \    
    geany geany-plugins-common \
    imagemagick \
    libreoffice \
    libnss-wrapper \
    ttf-wqy-zenhei \
    gettext \
    pinta \
    xfce4 \
    xfce4-terminal \
    xterm \
    evince \
    ansible \
    git \
    zip \
    unzip \
    iputils-ping \
    build-essential \
    openssh-client \
    openssl \
    dnsutils \
    screen \
    smbclient \
    rsync \
    whois \
    netcat \
    nmap \
    terminator \
    tmux \
    vim \
    vlc \
    locales \
    bzip2 \
    xdotool \
    xautomation

RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    rm -f packages.microsoft.gpg && \
    apt-get -y install apt-transport-https && \
    apt-get update && \
    apt-get -y install code

#----------------------------------
# We install firefox, directly from Mozilla (not from snap)
RUN     \
        echo "Install Firefox from Mozilla" >&2               \
        && apt-get update                                     \
        && add-apt-repository ppa:mozillateam/ppa             \
        && printf '\nPackage: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/mozilla-firefox                     \
        && printf 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' > /etc/apt/apt.conf.d/51unattended-upgrades-firefox \
        && apt-get update                                     \
        && apt-get install -y firefox --no-install-recommends \
        && apt-get clean                                      \
        && apt-get autoremove -y                              \
        && rm -rf /tmp/* /var/tmp/*                           \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/*       \
        && echo "Install Firefox from Mozilla OK" >&2
#Brave - source
RUN \
    echo "Install Firefox from Mozilla" >&2 \
    && curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|tee /etc/apt/sources.list.d/brave-browser-release.list && \
#PeaZip - source
    wget https://github.com/peazip/PeaZip/releases/download/8.2.0/peazip_8.2.0.LINUX.GTK2-1_amd64.deb -P /tmp && \
#Sublime - source
    curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add - && \
    add-apt-repository "deb https://download.sublimetext.com/ apt/stable/" && \
#Installation
    apt-get update && \
    apt-get install --no-install-recommends brave-browser /tmp/peazip_8.2.0.LINUX.GTK2-1_amd64.deb sublime-text -y \
    && echo "Install Firefox from Mozilla OK" >&2
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



