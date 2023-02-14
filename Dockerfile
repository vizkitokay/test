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

WORKDIR $HOME

RUN apt-get update

RUN apt-get install -y python3 python-is-python3 python3-pip software-properties-common tzdata sudo x11vnc xvfb xdotool wget tar curl supervisor net-tools apt-utils locales language-pack-en language-pack-en-base ; update-locale 

RUN apt-get install -y \
    xfce4 \
    xfce4-terminal \
    xterm \
    iputils-ping \
    build-essential \
    openssh-client \
    openssl \
    dnsutils \
    screen \
    terminator \
    tmux \
    vim \
    vlc \
    locales \
    xdotool \
    xautomation

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

#------------------------------------------------------------

### noVNC needs python2 and ubuntu docker image is not providing any default python
RUN test -e /usr/bin/python && rm -f /usr/bin/python ; ln -s /usr/bin/python3 /usr/bin/python

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



