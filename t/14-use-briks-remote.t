use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Remote::Tcpdump"); $@ ? 0 : 1 }, 1, $@);
