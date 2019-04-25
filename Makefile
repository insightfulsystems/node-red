export IMAGE_NAME?=insightful/node-red
export VCS_REF=`git rev-parse --short HEAD`
export VCS_URL=https://github.com/insightfulsystems/node-red
export BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
export TAG_DATE=`date -u +"%Y%m%d"`
export BUILD_IMAGE_NAME=insightful/alpine-node
export NODE_MAJOR_VERSION=10
export TARGET_ARCHITECTURES=amd64 arm32v7 arm32v6
export TAGS=base bots automation
export BUNDLES=slim build
export BUNDLE?=slim
export TAG?=base
export ARCH?=amd64

# Permanent local overrides
-include .env

.PHONY: qemu wrap node push manifest clean

qemu:
	-docker run --rm --privileged multiarch/qemu-user-static:register --reset

env:
	echo "\n\n\n*** Building $(BUNDLE) $(TAG) for $(ARCH) ***\n\n\n" && \
	cp tags/$(TAG)/package.json bundles/$(BUNDLE)/package.json && \
	docker build --build-arg BUILD_DATE=$(BUILD_DATE) \
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
			echo "\n\n\n*** Building $(BUNDLE) $(TAG) for $(ARCH) ***\n\n\n" && \
			cp tags/$(TAG)/package.json bundles/$(BUNDLE)/package.json && \
			docker build --build-arg BUILD_DATE=$(BUILD_DATE) \
				--build-arg ARCH=$(ARCH) \
				--build-arg BASE=$(BUILD_IMAGE_NAME):$(NODE_MAJOR_VERSION)-$(ARCH) \
				--build-arg VCS_REF=$(VCS_REF) \
				--build-arg VCS_URL=$(VCS_URL) \
				-t $(IMAGE_NAME):$(BUNDLE)-$(TAG)-$(ARCH) bundles/$(BUNDLE) \
		;) \
	)

push:
	docker push $(IMAGE_NAME)

push-%:
	$(eval TAG := $*)
	$(foreach ARCH, $(TARGET_ARCHITECTURES), \
		$(foreach BUNDLE, $(BUNDLES), \
			docker push $(IMAGE_NAME):$(BUNDLE)-$(TAG)-$(ARCH) \
		;) \
	)

manifest:
	$(foreach BUNDLE, $(BUNDLES), \
		docker manifest create --amend \
			$(IMAGE_NAME):$(BUNDLE) \
			$(foreach ARCH, $(TARGET_ARCHITECTURES), $(IMAGE_NAME):$(BUNDLE)-base-$(ARCH)); \
		docker manifest push $(IMAGE_NAME):$(BUNDLE) \
	;)
	docker manifest create --amend \
		$(IMAGE_NAME):latest \
		$(foreach ARCH, $(TARGET_ARCHITECTURES), $(IMAGE_NAME):slim-base-$(ARCH))
	docker manifest push $(IMAGE_NAME):latest

clean:
	-docker rm -fv $$(docker ps -a -q -f status=exited)
	-docker rmi -f $$(docker images -q -f dangling=true)
	-docker rmi -f $(BUILD_IMAGE_NAME)
	-docker rmi -f $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep $(IMAGE_NAME))

