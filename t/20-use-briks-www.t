use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Www::Client"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Www::Googlesafebrowsing"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Www::Util"); $@ ? 0 : 1 }, 1, $@);
