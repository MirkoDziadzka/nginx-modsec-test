
all:
	$(MAKE) run

build:
	docker build . --tag nginx-modsec

run: build
	docker run --rm -p 8080:80  nginx-modsec