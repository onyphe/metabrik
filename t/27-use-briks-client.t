use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Client::Www"); $@ ? 0 : 1 }, 1, $@);
