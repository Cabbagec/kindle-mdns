.PHONY: build pack

build:
	cross build --release --target armv7-unknown-linux-musleabihf

pack: build
	cp ./target/armv7-unknown-linux-musleabihf/release/kindle-mdns ./extensions/kindle-mdns/bin/
	zip -r9 kindle-mdns.zip ./extensions