LUVIT   := $(shell which luvit)

test: tmp/usr/bin/busybox
	echo Testing
	( cd test ; sudo $(LUVIT) ./test )

tmp/usr/bin/busybox:
	echo Preparing sandbox
	mkdir -p tmp
	wget -qct3 http://www.landley.net/aboriginal/downloads/binaries/root-filesystem/simple-root-filesystem-i686.tar.bz2 -O - | tar -xjpf - --strip 1 -C tmp
	sudo chown -R 500:500 tmp/home

docs:
	#ndoc

.PHONY: test docs
.SILENT:
