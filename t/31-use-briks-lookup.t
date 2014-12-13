use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Lookup::Ethernet"); $@ ? 0 : 1 }, 1, $@);
