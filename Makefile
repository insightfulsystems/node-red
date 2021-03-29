export IMAGE_NAME?=insightful/node-red
export PRIVATE_REGISTRY?=registry.lan:5000
export VCS_REF=`git rev-parse --short HEAD`
export VCS_URL=https://github.com/insightfulsystems/node-red
export BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
export TAG_DATE=`date -u +"%Y%m%d"`
export BUILD_IMAGE_NAME=insightful/alpine-node
export NODE_MAJOR_VERSION=14
export TARGET_ARCHITECTURES=amd64 arm32v7 arm32v6 arm64v8
export TAGS=automation base
export BUNDLES=build slim
export BUNDLE?=slim
export TAG?=base
export ARCH?=amd64
export SHELL=/bin/bash

# Permanent local overrides
-include .env

.PHONY: qemu wrap node push manifest clean

qemu:
	-docker run --rm --privileged multiarch/qemu-user-static:register --reset

all: qemu node-red push manifest

env:
	echo -e "\n\n\n*** Building $(BUNDLE) $(TAG) for $(ARCH) ***\n\n" && \
	cp -a bundles/common bundles/$(BUNDLE) && \
	chmod a+x bundles/$(BUNDLE)/init
	cp tags/$(TAG)/package.json bundles/$(BUNDLE)/common/package.json && \
	docker build \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg ARCH=$(ARCH) \
		--build-arg BASE=$(BUILD_IMAGE_NAME):$(NODE_MAJOR_VERSION)-$(ARCH) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VCS_URL=$(VCS_URL) \
		-t $(IMAGE_NAME):$(BUNDLE)-$(TAG)-$(ARCH) bundles/$(BUNDLE) \

node-red:
	$(foreach tag, $(TAGS), make tag-$(tag);)

tag-%:
	$(eval TAG := $*)
	$(foreach ARCH, $(TARGET_ARCHITECTURES), \
		$(foreach BUNDLE, $(BUNDLES), \
			docker image prune -f --filter label=stage=base ; \
			docker image prune -f --filter label=stage=build ; \
			echo -e "\n\n\n*** Building $(BUNDLE) $(TAG) for $(ARCH) ***\n\n\n" && \
			cp -a bundles/common bundles/$(BUNDLE) && \
			chmod a+x bundles/$(BUNDLE)/common/*.sh && \
			cp tags/$(TAG)/package.json bundles/$(BUNDLE)/common/package.json && \
			docker build \
				--build-arg BUILD_DATE=$(BUILD_DATE) \
				--build-arg ARCH=$(ARCH) \
				--build-arg BASE=$(BUILD_IMAGE_NAME):$(NODE_MAJOR_VERSION)-$(ARCH) \
				--build-arg VCS_REF=$(VCS_REF) \
				--build-arg VCS_URL=$(VCS_URL) \
				-t $(IMAGE_NAME):$(BUNDLE)-$(TAG)-$(ARCH) bundles/$(BUNDLE) | sed -e 's/^/$(BUNDLE) $(TAG) $(ARCH): /;' && \
			rm -rf bundles/$(BUNDLE)/common \
		;) \
	)

push:
	docker push $(IMAGE_NAME)

push-%:
	$(eval TAG := $*)
	$(foreach ARCH, $(TARGET_ARCHITECTURES), \
		$(foreach BUNDLE, $(BUNDLES), \
			docker tag $(IMAGE_NAME):$(BUNDLE)-$(TAG) $(IMAGE_NAME):$(TAG) && \ 
			docker tag $(IMAGE_NAME):$(BUNDLE)-$(TAG) $(IMAGE_NAME):latest && \ 
			docker push $(IMAGE_NAME):$(BUNDLE)-$(TAG)-$(ARCH) \
		;) \
	)

expand-%: # expand architecture variants for manifest
	@if [ "$*" == "amd64" ] ; then \
	   echo '--arch $*'; \
	elif [[ "$*" == *"arm"* ]] ; then \
	   echo '--arch arm --variant $*' | cut -c 1-21,27-; \
	fi

manifest:
	$(foreach BUNDLE, $(BUNDLES), \
		docker manifest create --amend $(IMAGE_NAME):$(BUNDLE) \
			$(foreach ARCH, $(TARGET_ARCHITECTURES), $(IMAGE_NAME):$(BUNDLE)-base-$(ARCH)); \
		 $(foreach arch, $(TARGET_ARCHITECTURES), \
			docker manifest annotate $(IMAGE_NAME):$(BUNDLE) \
				$(IMAGE_NAME):$(BUNDLE)-base-$(arch) $(shell make expand-$(arch));) \
	       	docker manifest push $(IMAGE_NAME):$(BUNDLE) \
	;) 
	docker manifest create --amend $(IMAGE_NAME):latest \
		$(foreach ARCH, $(TARGET_ARCHITECTURES), $(IMAGE_NAME):slim-base-$(ARCH))
	$(foreach arch, $(TARGET_ARCHITECTURES), \
		docker manifest annotate $(IMAGE_NAME):latest \
	       		$(IMAGE_NAME):slim-base-$(arch) $(shell make expand-$(arch));)
	docker manifest push $(IMAGE_NAME):latest

local-push-arm32v7:
	$(foreach BUNDLE, $(BUNDLES), docker tag \
	      	$(IMAGE_NAME):$(BUNDLE)-base-arm32v7 \
		$(PRIVATE_REGISTRY)/$(IMAGE_NAME):$(BUNDLE) \
	;)
	docker push $(PRIVATE_REGISTRY)/$(IMAGE_NAME)


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
