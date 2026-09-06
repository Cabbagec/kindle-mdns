use clap::Parser;
use mdns_sd::{IfKind, ServiceDaemon, ServiceInfo};
use std::process::exit;

#[derive(Parser)]
struct Args {
    #[arg(short, long, default_value = "_kindle-service._tcp")]
    service_type: Option<String>,
    #[arg(short, long, default_value = "Kindle Service")]
    instance_name: Option<String>,
    #[arg(short, long, default_value = "0")]
    port: Option<u16>,
    host_name: String,
    #[arg(long = "disable-ipv6", default_value_t = false)]
    disable_ipv6: bool,
}

fn main() {
    let args = Args::parse();
    let Ok(service) = ServiceInfo::new(
        format!("{}.local.", args.service_type.unwrap()).as_str(),
        args.instance_name.unwrap().as_str(),
        format!("{}.local.", args.host_name).as_str(),
        "",
        args.port.unwrap(),
        None,
    ) else {
        eprintln!("Failed to create ServiceInfo");
        exit(1);
    };
    let service = service.enable_addr_auto();
    let Ok(mdns) = ServiceDaemon::new() else {
        eprintln!("Failed to create ServiceDaemon");
        exit(1);
    };
    if args.disable_ipv6 {
        let _ = mdns.disable_interface(IfKind::IPv6);
    }

    if let Err(err) = mdns.register(service) {
        eprintln!("Failed to register service: {}", err);
        exit(1);
    }
    loop {
        std::thread::sleep(std::time::Duration::from_secs(10));
    }
}
