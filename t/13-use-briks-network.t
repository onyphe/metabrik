use Test;
BEGIN { plan(tests => 14) }

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
