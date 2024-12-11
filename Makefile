.PHONY: build pack
TARGET ?= armv7-unknown-linux-musleabihf

build:
	cross build --release --target $(TARGET)

pack: clean build
	cp ./target/$(TARGET)/release/kindle-mdns ./extensions/kindle-mdns/bin/
	zip -r9 kindle-mdns-$(TARGET).zip ./extensions

clean:
	cargo clean
	rm -rf kindle-mdns-$(TARGET).zip