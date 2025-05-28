use clap::Parser;
use mdns_sd::{IfKind, ServiceDaemon, ServiceInfo};
use std::process::exit;

#[derive(Parser)]
struct Args {
    #[arg(short, long, default_value = "_my-hello._tcp")]
    service_type: Option<String>,
    #[arg(short, long, default_value = "instance1")]
    instance_name: Option<String>,
    host_name: String,
    #[arg(long = "disable-ipv6", default_value_t = false)]
    disable_ipv6: bool,
    #[arg(short, long, default_value = "")]
    ip_addresses: String,
}

fn main() {
    let args = Args::parse();
    let Ok(mut service) = ServiceInfo::new(
        format!("{}.local.", args.service_type.unwrap()).as_str(),
        args.instance_name.unwrap().as_str(),
        format!("{}.local.", args.host_name).as_str(),
        args.ip_addresses.as_str(),
        0,
        None,
    ) else {
        eprintln!("Failed to create ServiceInfo");
        exit(1);
    };
    if args.ip_addresses.len() == 0 {
        service = service.enable_addr_auto();
    }
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
