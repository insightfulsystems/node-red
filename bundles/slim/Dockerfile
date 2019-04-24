ARG BASE
FROM ${BASE}

# Home directory for Node-RED application source code.
# /data directory, contains flows, config and nodes.
# Add git binary for supporting projects feature
RUN mkdir -p /usr/src/node-red \
 && mkdir /data \
 && apk add --no-cache \
    git

WORKDIR /usr/src/node-red

# Add node-red user so we aren't running as root.
RUN adduser -h /usr/src/node-red -D -H node-red \
 && chown -R node-red:node-red /data \
 && chown -R node-red:node-red /usr/src/node-red

# package.json contains Node-RED NPM module and node dependencies
COPY ./package.json /usr/src/node-red/

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
 && yarn install --verbose \
 && rm -rf /usr/local/share/.cache \
 && apk del .build-deps

USER node-red

# User configuration directory volume
EXPOSE 1880

# Environment variable holding file path for flows configuration
ENV FLOWS=flows.json
ENV NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules

CMD ["npm", "start", "--", "--userDir", "/data"]
