ARG BASE_TAG="develop"
ARG BASE_IMAGE="core-ubuntu-jammy"
FROM hub.dlpu.top/kasmweb/$BASE_IMAGE:$BASE_TAG

USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
WORKDIR $HOME

### Envrionment config
ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=$STARTUPDIR/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=$STARTUPDIR/install \
    INST_SCRIPTS="/ubuntu/install/tools/install_tools_deluxe.sh \
                  /ubuntu/install/misc/install_tools.sh \
                  /ubuntu/install/chrome/install_chrome.sh \
                  /ubuntu/install/vs_code/install_vs_code.sh \
                  /ubuntu/install/firefox/install_firefox.sh \
                  /ubuntu/install/cleanup/cleanup.sh" 


# Copy install scripts
COPY ./src/ $INST_DIR
RUN apt-get update && apt-get install -y \
        libasound2 libegl1-mesa libgl1-mesa-glx \
        libxcomposite1 libxcursor1 libxi6 libxrandr2 libxss1 \
        libxtst6 gdal-bin ffmpeg vlc dnsutils iputils-ping \
        git 
# Run installations
RUN \
  for SCRIPT in $INST_SCRIPTS; do \
    bash ${INST_DIR}${SCRIPT} || exit 1; \
  done && \
  $STARTUPDIR/set_user_permission.sh $HOME && \
  rm -f /etc/X11/xinit/Xclients && \
  chown 1000:0 $HOME && \
  mkdir -p /home/kasm-user && \
  chown -R 1000:0 /home/kasm-user && \
  rm -Rf ${INST_DIR}

RUN cd /opt/ \
  && wget https://download.jetbrains.com/python/pycharm-community-2024.2.1.tar.gz \
  && tar xvf pycharm-community-*.tar.gz \
  && rm -rf pycharm-community-*.tar.gz \
  && mv /opt/pycharm-community-2024.2.1 /opt/pycharm

RUN apt update &&  apt install -y fcitx5 fcitx5-config-qt fcitx5-frontend-gtk4 fcitx5-pinyin && \
    apt install -y fonts-noto-cjk 

RUN wget https://f19fc6-1955528070.antpcdn.com:19001/b/pkg-ant.baidu.com/issue/netdisk/LinuxGuanjia/4.17.7/baidunetdisk_4.17.7_amd64.deb && dpkg -i baidunetdisk_4.17.7_amd64.deb && rm baidunetdisk_4.17.7_amd64.deb
COPY pycharm.desktop ${HOME}/Desktop/  
RUN sed -i '/STARTUP_COMPLETE=1/i\fcitx5 &' /dockerstartup/vnc_startup.sh
# RUN custom_startup.sh /dockerstartup/vnc_startup.sh
COPY .config /home/kasm-user/.config
RUN chown -R 1000:0 /home/kasm-user

ENV GTK_IM_MODULE=fcitx \
    QT_IM_MODULE=fcitx \
    XMODIFIERS=@im=fcitx
RUN echo 'kasm-user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV PATH="/home/lyj/anaconda3/bin:$PATH"

# Userspace Runtime
ENV HOME /home/kasm-user
WORKDIR $HOME
USER 1000

CMD ["--tail-log"]
