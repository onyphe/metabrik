use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Netbios::Name"); $@ ? 0 : 1 }, 1, $@);
