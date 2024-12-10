.PHONY: build pack

build:
	cross build --release --target armv7-unknown-linux-musleabihf

pack: build
	rm -rf kindle-mdns.zip
	cp ./target/armv7-unknown-linux-musleabihf/release/kindle-mdns ./extensions/kindle-mdns/bin/
	zip -r9 kindle-mdns.zip ./extensions

clean:
	cargo clear
	rm kindle-mdns.zip