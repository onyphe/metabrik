use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::Api::Splunk"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Bluecoat"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Virustotal"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Shodan"); $@ ? 0 : 1 }, 1, $@);
