use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Convert::Video"); $@ ? 0 : 1 }, 1, $@);
