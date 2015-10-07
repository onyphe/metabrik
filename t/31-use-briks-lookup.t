use Test;
BEGIN { plan(tests => 8) }

ok(sub { eval("use Metabrik::Lookup::Ethernet"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Ip"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Protocol"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Service"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Oui"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Tcpoption"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Ipoption"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Lookup::Iplocation"); $@ ? 0 : 1 }, 1, $@);
