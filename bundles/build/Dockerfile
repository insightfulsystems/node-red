ARG BASE
FROM ${BASE}

# Home directory for Node-RED application source code.
# /data directory, contains flows, config and nodes.
# This image includes the build tools permanently
RUN mkdir -p /usr/src/node-red \
 && mkdir /data \
 && apk add --no-cache \
    git \
    binutils-gold \
    curl \
    g++ \
    gcc \
    gnupg \
    libgcc \
    linux-headers \
    make \
    python 

WORKDIR /usr/src/node-red

# Add node-red user so we aren't running as root.
RUN adduser -h /usr/src/node-red -D -H node-red \
 && chown -R node-red:node-red /data \
 && chown -R node-red:node-red /usr/src/node-red

# package.json contains Node-RED NPM module and node dependencies
COPY ./package.json /usr/src/node-red/

USER node-red

# Set C compiler flags to work around grpc compile errors in ARM
RUN CXXFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    CFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    yarn install \
 && rm -rf /usr/src/node-red/.cache

# User configuration directory volume
EXPOSE 1880

# Environment variable holding file path for flows configuration
ENV FLOWS=flows.json
ENV NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules

CMD ["npm", "start", "--", "--userDir", "/data"]
