# docker.xfce-vnc
This is an xfce desktop which is intended to to be used for teaching env   
It is based on a ubuntu:latest image
You can access the image with vncviewer or webbrowser directly

# This image includes the following software
- xfce desktop
- Libre Office
- Pinta
- Terminator
- Geany
- Visual Studio Code
- Firefox
- Tor Browser
- Git
- OpenSSL
- Nmap
- Ansible
- Screen
- Tmux

## RUN
```
docker run --env VNC_PW=secure. --env DEBUG=true --publish 5901:5901 --publish 6901:6901 xfce-vnc
```

<!-- ## ScreenShot
![](ss.png) -->
