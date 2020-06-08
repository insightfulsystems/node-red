#!/bin/sh

# This is already baked into our base image, no point in setting up another
USER=node

# Follow the linuxserver.io approach to setting UIDs
PUID=${PUID:-911}
PGID=${PGID:-911}

echo "UID:GID - $PUID:$PGID"

groupmod -o -g "$PGID" $USER
usermod -o -u "$PUID" $USER
usermod -d /usr/src/node-red $USER

chown -R $USER:$USER /data
chown -R $USER:$USER /usr/src/node-red

# CMD
sudo -H -E -u $USER /usr/local/bin/npm start -- --userDir /data
