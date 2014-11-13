use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Scanner::Nmap"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Scanner::Nikto"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Scanner::Sqlmap"); $@ ? 0 : 1 }, 1, $@);
