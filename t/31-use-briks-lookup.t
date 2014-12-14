use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Lookup::Ethernet"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Ip"); $@ ? 0 : 1 }, 1, $@);
