use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Devel::Git"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Devel::Mercurial"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Devel::Subversion"); $@ ? 0 : 1 }, 1, $@);
