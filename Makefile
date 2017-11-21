ifdef DOCKER_MACHINE_NAME
mounted_volume = /tmp$(PWD)
else
mounted_volume = $(PWD)
endif

.PHONY: help test rsync logs

.DEFAULT_GOAL := help

rsync:			## Synchronize working directory with docker-machine directory
	@if [ ! -z "$DOCKER_MACHINE_NAME" ]; then \
		echo "Syncing working directory with docker machine's directory '${mounted_volume}'" ; \
		docker-machine ssh ${DOCKER_MACHINE_NAME} mkdir -p ${mounted_volume} && \
		docker-machine scp -r -d ${PWD}/ ${DOCKER_MACHINE_NAME}:${mounted_volume}; \
	fi

test: rsync		## Test the role using Test Kitchen. By default 'kitchen test' is run. Different kitchen commands can be run using the 'cmd' variable. E.g.: 'make test cmd=converge'
	docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(mounted_volume):/workspace -w /workspace --net="host" contentwise/test-kitchen-ansible $${cmd:-test}

logs:			## Show logs available under the path specified by the 'path' variable. E.g.: 'make logs path=.kitchen/lgos/default-centos-72.log | less'
	@if [ ! -z "$DOCKER_MACHINE_NAME" ]; then \
		docker-machine ssh ${DOCKER_MACHINE_NAME} cat ${mounted_volume}/${path}; \
	else \
		cat ${mounted_volume}/${path}; \
	fi

help:			## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'