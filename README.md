### arm-mdns

Simple Zeroconf/mDNS server for ARM-based devices. This daemon allows your device to be discoverable on the local network using a friendly hostname.

#### What does this project do?

With arm-mdns running on your ARM device, you can reach it simply by the name `device.local` (or any custom hostname you choose) on other computers under the same network, without the hassle of figuring out the IP address.

e.g. you can ping the device by `ping device.local`, or ssh into it by `ssh user@device.local`, etc.
If DHCP or dynamic IP is enabled for your network, this daemon is particularly helpful.

Note that on Windows and macOS, zeroconf/mDNS discovery is enabled by default, you don't need to change any special configurations.
On Linux, you need to configure NSS for mdns and the avahi daemon,
checkout the [Arch Wiki](https://wiki.archlinux.org/title/Avahi) tutorial page.

#### How does it work? And what is zeroconf/mDNS?

Zeroconf (mDNS) is a protocol that allows devices to find each other by name, 
basically it sends out packets containing name and ip info of the device to multicast addresses on current network, 
so other devices can find it without the help from the typical DNS, hence the name m(ulticast)DNS.
This project implements a simple zeroconf/mDNS server with the `mdns_sd` crate.
It is used by many devices to advertise their presence on the network.

#### Install from zip file

1. Download the zip file from the Releases page
2. Extract the zip file on your ARM device
3. Navigate to the extracted `extensions/arm-mdns/bin` directory
4. Run the installation script: `sudo ./arm-mdns-control.sh install [hostname]`
   - If no hostname is provided, "device" will be used as the default
5. Start the service: `sudo ./arm-mdns-control.sh start`
6. (Optional) Enable the service to start at boot: `sudo ./arm-mdns-control.sh enable`

#### Build from source

There are two methods to build the project:

##### Method 1: Using the `cross` tool (Default)

Build requirements: docker, rust toolchains, rust `cross` crate, `make`

1. Clone this repo
2. Get rustup and cargo, see installation for [Rust](https://www.rust-lang.org/tools/install)
3. Install `cross` for cross compilation: `cargo install cross --git https://github.com/cross-rs/cross`
4. Setup docker, see installation for [Docker](https://docs.docker.com/get-docker/)
5. Build the zip package: `make pack`
   - For armv7 devices (default): `make pack`
   - For other ARM architectures: `TARGET=<target-triple> make pack`
   - This will create `arm-mdns-<target-triple>.zip`

##### Method 2: Using Docker BuildKit (Recommended)

Build requirements: docker with BuildKit support, `make`

This method uses Docker BuildKit to handle the entire build process, eliminating the need for local Rust toolchain installation.

1. Clone this repo
2. Setup docker with BuildKit, see installation for [Docker](https://docs.docker.com/get-docker/)
3. Build the zip package: `make BUILD_METHOD=docker pack`
   - For armv7 devices (default): `make BUILD_METHOD=docker pack`
   - For other ARM architectures: `make TARGET=<target-triple> BUILD_METHOD=docker pack`
   - This will create `arm-mdns-<target-triple>.zip`

The Docker BuildKit method offers several advantages:
- No need to install Rust or the `cross` tool locally
- Cleaner build process with no leftover artifacts
- Consistent build environment across different machines

You can determine your device's CPU architecture by running `uname -m`. Common ARM architectures:
- armv7: use `armv7-unknown-linux-musleabihf`
- aarch64: use `aarch64-unknown-linux-musl`

#### Service Management

The daemon comes with a control script that automatically detects your system's init system (systemd or init.d) and provides appropriate commands for service management:

```
./arm-mdns-control.sh {install [hostname]|start|stop|enable|disable|uninstall|status}
  install [hostname] - Install the service (optionally specify hostname, default: device)
  start             - Start the service
  stop              - Stop the service
  enable            - Enable service to start at boot
  disable           - Disable service from starting at boot
  uninstall         - Uninstall the service
  status            - Show service status
```

##### Init System Support

The control script supports multiple init systems:

1. **systemd** - Used on most modern Linux distributions
2. **init.d** - Used on older systems and some embedded devices
3. **watchdog** - For systems without a recognized init system, a standalone watchdog daemon is provided

The watchdog daemon for systems without init systems provides the following features:

- Automatic service monitoring and crash recovery
- Proper logging to /var/log or user's home directory
- PID file management for reliable service control
- Multiple startup options (rc.local, crontab)
- Full service lifecycle management (install, start, stop, status)

This ensures compatibility with a wide range of ARM devices, from modern systems to older embedded devices and very basic systems without standard init capabilities.

#### Note

The default hostname is `device.local`. You can specify a custom hostname during installation.
