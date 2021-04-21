# node-red

[![Docker Stars](https://img.shields.io/docker/stars/insightful/node-red.svg)](https://hub.docker.com/r/insightful/node-red)
[![Docker Pulls](https://img.shields.io/docker/pulls/insightful/node-red.svg)](https://hub.docker.com/r/insightful/node-red)
[![](https://images.microbadger.com/badges/image/insightful/node-red.svg)](https://microbadger.com/images/insightful/node-red "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/insightful/node-red.svg)](https://microbadger.com/images/insightful/node-red "Get your own version badge on microbadger.com")
[![Build Status](https://travis-ci.org/insightfulsystems/node-red.svg?branch=master)](https://travis-ci.org/insightfulsystems/node-red "Build Status")


```
docker run -p 1880:1880 insightful/node-red:slim-base # or slim-automation, or build-redbot, or build-viseo, etc.
```

Multi-arch Node-RED 1.3.3 containers based on the official images, with the following changes:

* Based on `alpine/3.13.4`
* Includes `git` to enable projects
* Includes the [midnight theme](https://github.com/node-red-contrib-themes/midnight-red), for sanity (check its docs to enable it).
* The `slim` tag strips out build tools for smaller containers
* The `build` tag includes build tools in the container
