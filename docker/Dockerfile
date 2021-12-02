FROM ubuntu:21.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y upgrade && apt-get -y install curl sudo zenity
RUN adduser --disabled-password \
--gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> \
/etc/sudoers
RUN echo "echo 'docker'" > /usr/bin/logname
USER docker

ENTRYPOINT ["/wayd/tests/install_test.sh"]