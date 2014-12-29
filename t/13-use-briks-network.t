use Test;
BEGIN { plan(tests => 26) }

ok(sub { eval("use Metabrik::Network::Frame"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Write"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Read"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Wlan"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Wps"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Nmap"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Nikto"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Sqlmap"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Netbios"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Ssdp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Route"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Arp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Device"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Arpdiscover"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Address"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Modbus"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::S7comm"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Icmp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Http"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Netstat"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Dns"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Smtp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Tor"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Whois"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Ftp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Traceroute"); $@ ? 0 : 1 }, 1, $@);
