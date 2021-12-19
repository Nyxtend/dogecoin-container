FROM ubuntu:latest

# Install dependencies
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -qqy && \
  DEBIAN_FRONTEND=noninteractive apt-get install -qqy \
    ca-certificates \
    curl \
    dirmngr \
    findutils \
    gpg \
    jq \
    rename \
    tar \
    util-linux

# Setup working environment
RUN mkdir -p /work
WORKDIR /work

# We want to support multiple architectures, so detect what type of agent we are
# building on and download the latest release of dogecoin using the github api.
RUN export ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x86_64-linux';; \
    arm64) ARCH='aarch64-linux';; \
    i386) ARCH='x86_64-linux';; \
    *) echo "Unsupported architecture"; exit 1 ;; \
  esac && \
  echo "Detected $ARCH architecture" && \
  curl -o latest-doge-release.json https://api.github.com/repos/dogecoin/dogecoin/releases/latest && \
  echo "Latest Dogecoin releases:" && \
  cat latest-doge-release.json && \
  DOWNLOAD_URL=$(jq --raw-output ".assets[] | select(.browser_download_url | contains(\"$ARCH\")).browser_download_url" latest-doge-release.json) && \
  echo "Downloading latest release from $DOWNLOAD_URL" && \
  curl -o doge.tar.gz -L $DOWNLOAD_URL && \
  tar -xvf doge.tar.gz && \
  rename 's/^dogecoin-.*/dogecoin/' dogecoin* && \
  rm latest-doge-release.json doge.tar.gz

# Add dogecoin binaries to path
ENV PATH="${PATH}:/work/dogecoin/bin/"

# Add dogecoin startup script
ADD docker-init.sh .
RUN chmod +x docker-init.sh

# ENVIRONMENT VARIABLES & CONFIGURATION
# The options below can be changed to alter the default behavior of
# the dogecoin startup script.

# SYNC_FROM_BOOTSTRAP_IF_UNINITIALIZED
#   The dogecoin blockchain takes a very long time to sync on the first run.
#   By default the docker-init.sh script will download a compressed copy of the
#   blockchain from https://bootstrap.sochain.com/. This sigificantly speeds
#   up sync time. Set to false to disable and perform a full node sync.
ENV SYNC_FROM_BOOTSTRAP_IF_UNINITIALIZED=true

# Expose dogecoin volume, this should be mounted to persistent storage
VOLUME [ "/root/.dogecoin" ]

# Expose the P2P port by default
#   Note: RPC port runs on 22555 by default on MAINNET
#         Be cautious if exposing the RPC port.
#   P2P port (22556 by default on MAINNET) should be forwarded to dogecoin.
EXPOSE 22556
CMD ["/work/docker-init.sh"]
