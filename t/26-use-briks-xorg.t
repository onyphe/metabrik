use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Xorg::Screenshot"); $@ ? 0 : 1 }, 1, $@);
