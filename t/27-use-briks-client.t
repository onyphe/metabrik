use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Client::Www"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Tcp"); $@ ? 0 : 1 }, 1, $@);
