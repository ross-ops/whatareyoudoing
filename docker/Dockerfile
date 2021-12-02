FROM ubuntu:21.04
RUN apt-get update && apt-get -y upgrade && apt-get -y install curl sudo
RUN adduser --disabled-password \
--gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> \
/etc/sudoers
USER docker

# ENTRYPOINT ["/wayd/tests/install_test.sh"]