use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Convert::Video"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Convert::Number"); $@ ? 0 : 1 }, 1, $@);
