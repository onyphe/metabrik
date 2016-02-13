use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Www::Shorten"); $@ ? 0 : 1 }, 1, $@);
