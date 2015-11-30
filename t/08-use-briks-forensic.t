use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Forensic::Dcfldd"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Forensic::Scalpel"); $@ ? 0 : 1 }, 1, $@);
