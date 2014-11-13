use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Http::Proxy"); $@ ? 0 : 1 }, 1, $@);
