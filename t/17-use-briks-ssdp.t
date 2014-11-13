use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Ssdp::Ssdp"); $@ ? 0 : 1 }, 1, $@);
