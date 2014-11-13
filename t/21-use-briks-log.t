use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Log::Dual"); $@ ? 0 : 1 }, 1, $@);
