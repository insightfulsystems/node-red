export IMAGE_NAME?=insightful/node-red
export PRIVATE_REGISTRY?=registry.lan:5000
export VCS_REF=`git rev-parse --short HEAD`
export VCS_URL=https://github.com/insightfulsystems/node-red
export BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
export TAG_DATE=`date -u +"%Y%m%d"`
export BUILD_IMAGE_NAME=alpine:3.16.0
export TAGS=automation base
export BUNDLES=build slim
export TARGET_ARCHITECTURES=linux/arm/v7,linux/arm/v6,linux/arm64,linux/amd64
export SHELL=/bin/bash

# Permanent local overrides
-include .env

.PHONY: buildx tags clean

buildx:
	-docker buildx create --name localbuilder
	-docker buildx use localbuilder
	-docker buildx inspect --bootstrap

env:
	echo -e "\n\n\n*** Building $(BUNDLE) $(TAG) for $(ARCH) ***\n\n" && \
	cp -a bundles/common bundles/$(BUNDLE) && \
	chmod a+x bundles/$(BUNDLE)/init
	cp tags/$(TAG)/package.json bundles/$(BUNDLE)/common/package.json && \
	docker  \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg ARCH=$(ARCH) \
		--build-arg BASE=$(BUILD_IMAGE_NAME):$(NODE_MAJOR_VERSION)-$(ARCH) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VCS_URL=$(VCS_URL) \
		-t $(IMAGE_NAME):$(BUNDLE)-$(TAG)-$(ARCH) bundles/$(BUNDLE) \

tags:
	$(foreach tag, $(TAGS), make tag-$(tag);)

tag-%:
	$(eval TAG := $*)
	$(foreach BUNDLE, $(BUNDLES), \
		docker image prune -f --filter label=stage=base ; \
		docker image prune -f --filter label=stage=build ; \
		echo -e "\n\n\n*** Building $(BUNDLE) $(TAG) ***\n\n\n" && \
		cp -a bundles/common bundles/$(BUNDLE) && \
		chmod a+x bundles/$(BUNDLE)/common/*.sh && \
		cp tags/$(TAG)/package.json bundles/$(BUNDLE)/common/package.json && \
		docker buildx build --platform $(TARGET_ARCHITECTURES) \
			--build-arg BUILD_DATE=$(BUILD_DATE) \
			--build-arg BASE=$(BUILD_IMAGE_NAME) \
			--build-arg VCS_REF=$(VCS_REF) \
			--build-arg VCS_URL=$(VCS_URL) \
			-t $(IMAGE_NAME):$(BUNDLE)-$(TAG) \
			--push bundles/$(BUNDLE) | sed -e 's/^/$(BUNDLE) $(TAG) $(ARCH): /;' && \
		rm -rf bundles/$(BUNDLE)/common \
	;) 


test:
	docker run \
		-p 0.0.0.0:1880:1880 \
		-ti $(IMAGE_NAME):$(BUNDLE)-$(TAG)-$(ARCH)

clean:
	-rm -rf ./tmp
	-$(foreach BUNDLE, $(BUNDLES), \
		rm -rf bundles/$(BUNDLE)/common \
	;)
	-docker rm -fv $$(docker ps -a -q -f status=exited)
	-docker rmi -f $$(docker images -q -f dangling=true)
	#-docker rmi -f $$(docker images | grep '^<none>' | awk '{print $3}')
	-docker rmi -f $(BUILD_IMAGE_NAME)
	-docker rmi -f $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep $(IMAGE_NAME))
	-docker rmi -f $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep $(BUILD_IMAGE_NAME))

nuke-everything-from-orbit:
	-docker image prune
	-docker rm -vf $$(docker ps -a -q)
	-docker rmi -f $$(docker images -a -q)
