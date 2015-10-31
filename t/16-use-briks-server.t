use Test;
BEGIN { plan(tests => 6) }

ok(sub { eval("use Metabrik::Server::Agent"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Http"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Dns"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Snmp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Snmptrap"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Tcp"); $@ ? 0 : 1 }, 1, $@);
