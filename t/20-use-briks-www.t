use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Www::Splunk"); $@ ? 0 : 1 }, 1, $@);
