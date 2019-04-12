FROM ubuntu:16.04 as swiftformat

ARG SWIFTFORMAT_VERSION=0.40.0

RUN set -ex \
    && apt-get update \
    && apt-get install -y apt-transport-https zip wget software-properties-common \
    && wget -q https://repo.vapor.codes/apt/keyring.gpg -O- | apt-key add - \
    && echo "deb https://repo.vapor.codes/apt $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/vapor.list \
    && apt-get update \
    && apt-get install -y vapor \

    # swiftformat
    && git clone -b ${SWIFTFORMAT_VERSION} --single-branch --depth 1 https://github.com/nicklockwood/SwiftFormat.git \
    && cd SwiftFormat \
    && swift build -c release \
    && cp .build/release/swiftformat /usr/bin/swiftformat \
    && cd .. \
    && rm -rf SwiftFormat

WORKDIR /opt/swiftbox
