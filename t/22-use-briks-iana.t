use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Iana::Countrycode"); $@ ? 0 : 1 }, 1, $@);
