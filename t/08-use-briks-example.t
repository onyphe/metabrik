use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Example::Template"); $@ ? 0 : 1 }, 1, $@);
