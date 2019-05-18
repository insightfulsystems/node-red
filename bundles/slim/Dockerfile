ARG BASE
FROM ${BASE}

# Home directory for Node-RED application source code.
# /data directory, contains flows, config and nodes.
# Add git binary for supporting projects feature
RUN mkdir -p /usr/src/node-red \
 && mkdir /data \
 && apk add --no-cache \
    git \
    shadow

WORKDIR /usr/src/node-red

# package.json contains Node-RED NPM module and node dependencies
COPY ./package.json /usr/src/node-red/
# Add our minimalist init script
ADD ./init.sh /init

# This image includes the build tools but removes them after installing modules
RUN apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python \
 && CXXFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    CFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    yarn install \
 && rm -rf /usr/local/share/.cache \
 && apk del .build-deps \
 && chmod +x /init

# User configuration directory volume
EXPOSE 1880

# Environment variable holding file path for flows configuration
ENV FLOWS=flows.json
ENV NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules

# Allow user to set uid/gid for Docker process
ENV PGID=1000
ENV PUID=1000

CMD ["/init"]
