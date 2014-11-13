use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Remote::Tcpdump"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Remote::Ssh2"); $@ ? 0 : 1 }, 1, $@);
