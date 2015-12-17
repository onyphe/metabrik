use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Devel::Mercurial"); $@ ? 0 : 1 }, 1, $@);
