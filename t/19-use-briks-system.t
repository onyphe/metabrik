use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::System::Os"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Service"); $@ ? 0 : 1 }, 1, $@);
