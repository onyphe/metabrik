use Test;
BEGIN { plan(tests => 7) }

ok(sub { eval("use Metabrik::Brik::Search"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Find"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Perl::Module"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Shell::Command"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Shell::History"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Shell::Rc"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Shell::Script"); $@ ? 0 : 1 }, 1, $@);
