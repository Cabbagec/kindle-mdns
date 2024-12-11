### kindle-mdns

Simple Zeroconf/mDNS server for your jailbroken kindle. KUAL is required. 
Currently, this plugin is tested on my KT3.

#### What does this project do?

With kindle-mdns running on your kindle, you can reach it simply by the name `kindle.local` on other computers under the same network,
without the hassle of figuring out the IP address.

e.g. you can ping the kindle by `ping kindle.local`, or ssh into it by `ssh root@kindle.local -i <keyfile>`, etc.
If DHCP or dynamic IP is enabled for your network, this plugin would be particularly helpful. 

Note that on Windows and macOS, zeroconf/mDNS discovery is enabled by default, you don't need to change any special configurations.
On linux, you need to configure NSS for mdns and the avahi daemon,
checkout the [Arch Wiki](https://wiki.archlinux.org/title/Avahi) tutorial page.

#### How does it work? And what is zeroconf/mDNS?

Zeroconf (mDNS) is a protocol that allows devices to find each other by name, 
basically it sends out packets containing name and ip info of the device to multicast addresses on current network, 
so other devices can find it without the help from the typical DNS, hence the name m(ulticast)DNS.
And this project implements a simple zeroconf/mDNS server with the `mdns_sd` crate.
It is used by many devices to advertise their presence on the network.

#### Install from zip file

Download the zip file from [Release](https://github.com/Cabbagec/kindle-mdns/releases), unzip and copy (overwrite/merge) the `extensions` folder to root dir of your kindle.
Now you can find the kindle-mdns entry under KUAL menus.

#### Build from source

build requirements: docker, rust toolchains, rust `cross` crate, `make`

1. clone this repo, `git clone https://github.com/Cabbagec/kindle-mdns`
2. get rustup and cargo, see installation for [Rust](https://www.rust-lang.org/tools/install).
3. install `cross` for cross compilation, `cargo install cross --git https://github.com/cross-rs/cross`
4. setup docker, see installation for [Docker](https://docs.docker.com/get-docker/)
5. build the zip package. `musl` targets are the preferred ones, these static binaries tend to be more compatible.
   * for KT3 and other similar armv7 devices, run `make pack`, then you get `kindle-mdns-armv7-unknown-linux-musleabihf.zip`
   * for other kindle devices, run `TARGET=<target-triple> make pack`, then you get `kindle-mdns-<target-triple>.zip`

you can figure out cpu type of your kindle by running `uname -m`, typically, it's `aarch64` or `armv7`,
and the triple should be `aarch64-unknown-linux-musl` or `armv7-unknown-linux-musleabihf`, respectively.

#### Note

The default host name is `kindle.local`. you can change it by modifying the `HOST_NAME` variable in `extensions/kindle-mdns/bin/start-stop.sh`.


