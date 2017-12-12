
all:
	$(MAKE) run

build:
	git submodule update
	docker build . --tag nginx-modsec

run: build
	docker run --rm -p 8080:80  nginx-modsec

shell: build
	docker run --rm -it nginx-modsec /bin/bash
