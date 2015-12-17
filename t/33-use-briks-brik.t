use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Brik::Tool"); $@ ? 0 : 1 }, 1, $@);
