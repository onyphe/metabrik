use Test;
BEGIN { plan(tests => 10) }

ok(sub { eval("use Metabrik::Server::Dns"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Elasticsearch"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Http"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Rest"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Snmp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Snmptrap"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Syslogng"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Tcp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Tor"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Kibana"); $@ ? 0 : 1 }, 1, $@);
