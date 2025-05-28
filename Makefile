.PHONY: build docker-build pack install clean clean-docker
TARGET ?= armv7-unknown-linux-musleabihf
BUILD_METHOD ?= cross

build:
ifeq ($(BUILD_METHOD),docker)
	$(MAKE) docker-build
else
	cross build --release --target $(TARGET)
endif

docker-build:
	DOCKER_BUILDKIT=1 docker build --build-arg TARGET=$(TARGET) \
		--output type=local,dest=. \
		-t arm-mdns-builder:$(TARGET) .
	$(MAKE) clean-docker

pack: clean build
ifeq ($(BUILD_METHOD),docker)
	zip -r9 arm-mdns-$(TARGET).zip ./extensions
else
	cp ./target/$(TARGET)/release/arm-mdns ./extensions/arm-mdns/bin/
	chmod +x ./extensions/arm-mdns/bin/arm-mdns-control.sh
	chmod +x ./extensions/arm-mdns/bin/init.d-script
	chmod +x ./extensions/arm-mdns/bin/arm-mdns-watchdog.sh
	zip -r9 arm-mdns-$(TARGET).zip ./extensions
endif

install: pack
	@echo "To install the service on your ARM device:"
	@echo "1. Extract the arm-mdns-$(TARGET).zip file on your device"
	@echo "2. Navigate to the extracted extensions/arm-mdns/bin directory"
	@echo "3. Run: sudo ./arm-mdns-control.sh install [hostname]"
	@echo "4. Start the service: sudo ./arm-mdns-control.sh start"
	@echo "5. (Optional) Enable at boot: sudo ./arm-mdns-control.sh enable"

clean:
	cargo clean
	rm -rf arm-mdns-$(TARGET).zip

clean-docker:
	-docker rmi arm-mdns-builder:$(TARGET) 2>/dev/null || true
