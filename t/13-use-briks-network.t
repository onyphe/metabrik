use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Network::Frame"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Write"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Network::Read"); $@ ? 0 : 1 }, 1, $@);
