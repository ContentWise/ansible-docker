.PHONY: help test logs

.DEFAULT_GOAL := help

ifeq ($(shell if docker-machine active > /dev/null 2>&1 ; then echo true; else echo false; fi),true)
	WORKDIR = /tmp$(PWD)
else
	WORKDIR = $(PWD)
endif

define docker_machine_rsync
	if [ -n "$(1)" ] && docker-machine active > /dev/null 2>&1 ; then \
		ssh-add ~/.docker/machine/machines/`docker-machine active`/id_rsa ; \
		rsync -avP -e "docker-machine ssh `docker-machine active`" --delete --exclude .git/ --exclude .gitignore --exclude-from .gitignore $(1)/ :/tmp`pwd` ; \
	fi
endef

test:			## Test the role using Test Kitchen. By default 'kitchen test' is run. Different kitchen commands can be run using the 'cmd' variable (e.g.: 'make test cmd=converge')
	@$(call docker_machine_rsync,$(PWD))
	@docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(WORKDIR):/workdir -w /workdir --net="host" contentwise/test-kitchen-ansible $${cmd:-test}

logs:			## Show logs available under the path specified by the 'path' variable. E.g.: 'make logs path=.kitchen/lgos/default-centos-72.log | less'
	@if docker-machine active > /dev/null 2>&1; then \
		docker-machine ssh `docker-machine active` cat ${WORKDIR}/${path}; \
	else \
		cat ${WORKDIR}/${path}; \
	fi

help:			## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'