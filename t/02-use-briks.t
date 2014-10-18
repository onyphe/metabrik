use Test;
BEGIN { plan(tests => 9) }

ok(sub { eval("use Metabrik::Brik::Brik::Search");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::File::Find");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::File::Read");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::File::Write");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Remote::Ssh2");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Shell::History");       $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Shell::Rc");            $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Shell::Script");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Shell::Command");       $@ ? 0 : 1 }, 1, $@);
