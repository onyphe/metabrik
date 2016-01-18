use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Log::Dual"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Log::File"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Log::Null"); $@ ? 0 : 1 }, 1, $@);
