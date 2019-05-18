# node-red

```
docker pull insightful/node-red:slim-automation
```

Multi-arch Node-RED containers based on the official images, and the following changes:

* Includes `git` to enable "projects"
* Uses `yarn` for baking in native packages
* The `slim` tag strips out build tools for smaller containers
* The `build` tag includes build tools in the container
