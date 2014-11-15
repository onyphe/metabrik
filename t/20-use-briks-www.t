use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Www::Client"); $@ ? 0 : 1 }, 1, $@);
