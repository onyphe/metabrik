use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Image::Jpg"); $@ ? 0 : 1 }, 1, $@);
