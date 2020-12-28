ARG BASE

FROM ${BASE} as base
LABEL stage=base

RUN set -ex \
 && apk add --no-cache \
    avahi-compat-libdns_sd \
    bash \
    curl \
    git \
    sudo \
    shadow \
    iputils \
    curl \
    sudo \
    tzdata \
    openssl \
    openssh-client \
 && mkdir -p /usr/src/node-red /data \
 && deluser --remove-home node \
 && adduser -h /usr/src/node-red -D -H node-red -u 1000 \
 && chown -R node-red:root /data && chmod -R g+rwX /data \
 && chown -R node-red:root /usr/src/node-red \
 && chmod -R g+rwX /usr/src/node-red

WORKDIR /usr/src/node-red

# package.json contains Node-RED NPM module and node dependencies
COPY common/package.json .
# flows.json contains a simple warning to users in case they forget to mount /data
COPY common/flows.json /data
# A minimalist init script
COPY common/init.sh /init

FROM base AS build
LABEL stage=build

# Install Build tools
RUN apk add --no-cache --virtual .build-deps \
    avahi-dev \
    build-base \
    linux-headers \
    python2 \
    sqlite \
    sqlite-dev \
    udev \
 && CXXFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    CFLAGS="-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation" \
    npm install --unsafe-perm --no-update-notifier --no-fund --only=production \
 && cp -R node_modules prod_node_modules \
 && apk del .build-deps

FROM base AS release
LABEL stage=release

ARG ARCH
ARG BUILD_DATE
ARG BUILD_VERSION
ARG NODE_RED_VERSION
ARG VCS_REF
ARG VCS_URL

COPY --from=build /usr/src/node-red/prod_node_modules ./node_modules

RUN mkdir -p /usr/src/node-red /data \
 && apk add --no-cache \
    avahi-dev \
    binutils-gold \
    build-base \ 
    gnupg \
    linux-headers \
    make \
    python2 \
    python3 \
    sqlite \
    udev 

ENV \
    FLOWS=flows.json \
    NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules \
    NODE_RED_VERSION=$NODE_RED_VERSION \
    PUID=1000 \
    GUID=1000

# Uncomment to enable safe start mode (flows not running)
# ENV NODE_RED_ENABLE_SAFE_MODE=true
# Uncomment to enable projects option
# ENV NODE_RED_ENABLE_PROJECTS=true

# Expose Node-RED port
EXPOSE 1880

# Add a healthcheck (default every 30 secs)
HEALTHCHECK CMD curl http://localhost:1880/ || exit 1

ENTRYPOINT ["/init"]

LABEL \
    authors="Dave Conway-Jones, Nick O'Leary, James Thomas, Raymond Mouthaan" \
    maintainer="Rui Carmo" \
    org.label-schema.arch=${ARCH} \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.description="Low-code programming for event-driven applications." \
    org.label-schema.docker.dockerfile="slim/Dockerfile" \
    org.label-schema.license="Apache-2.0" \
    org.label-schema.name="Node-RED" \
    org.label-schema.url="https://nodered.org" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.build-date=${BUILD_DATE} \
