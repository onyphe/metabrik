use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Address::Generate"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Address::Netmask"); $@ ? 0 : 1 }, 1, $@);
