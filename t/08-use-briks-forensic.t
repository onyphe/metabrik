use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::Forensic::Dcfldd"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Forensic::Scalpel"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Forensic::Volatility"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Forensic::Sysmon"); $@ ? 0 : 1 }, 1, $@);
