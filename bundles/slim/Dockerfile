ARG BASE
FROM ${BASE}

# Home directory for Node-RED application source code.
# /data directory, contains flows, config and nodes.
# Add git binary for supporting projects feature
RUN mkdir -p /usr/src/node-red \
 && mkdir /data \
 && apk add --no-cache \
    avahi-compat-libdns_sd \
    git \
    sudo \
    shadow \
    iputils \
    curl \
    tzdata

WORKDIR /usr/src/node-red

# package.json contains Node-RED NPM module and node dependencies
COPY ./package.json /usr/src/node-red/
# Add our minimalist init script
ADD ./init.sh /init

# This image includes the build tools but removes them after installing modules
RUN apk add --no-cache --virtual .build-deps \
        avahi-dev \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python2 \
 && CXXFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    CFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    yarn install \
 && rm -rf /usr/local/share/.cache \
 && apk del .build-deps \
 && chmod +x /init \
 && npm config set prefix /data \
 && yarn config set prefix /data

# Environment variable holding file path for flows configuration
ENV FLOWS=flows.json
ENV NODE_PATH=/data/node_modules:/usr/src/node-red/node_modules

# User configuration directory volume
VOLUME ["/data"]

# Expose the listening port of node-red
EXPOSE 1880

# Allow user to set uid/gid for Docker process
ENV PGID=1000
ENV PUID=1000

# Add a healthcheck (default every 30 secs)
HEALTHCHECK CMD curl http://localhost:1880/ || exit 1

ENTRYPOINT ["/init"]
