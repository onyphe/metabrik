use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Terminal::Asciinema"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Terminal::Showterm"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Terminal::Control"); $@ ? 0 : 1 }, 1, $@);
