use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Api::Splunk"); $@ ? 0 : 1 }, 1, $@);
