use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Hardware::Battery"); $@ ? 0 : 1 }, 1, $@);
