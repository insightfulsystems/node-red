#!/bin/sh

USER=node-red

# Follow the linuxserver.io approach to setting UIDs
PUID=${PUID:-911}
PGID=${PGID:-911}

echo "UID:GID - $PUID:$PGID"

echo "Setting user permissions..."

groupmod -o -g "$PGID" $USER
usermod -o -u "$PUID" $USER

echo "Starting..."

# CMD
sudo -H -E -u $USER /usr/local/bin/npm start --cache /data/.npm -- --userDir /data
