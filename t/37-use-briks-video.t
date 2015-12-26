use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Video::Convert"); $@ ? 0 : 1 }, 1, $@);
