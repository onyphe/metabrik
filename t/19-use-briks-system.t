use Test;
BEGIN { plan(tests => 7) }

ok(sub { eval("use Metabrik::System::Os"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Service"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Ubuntu::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Jail"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Pf"); $@ ? 0 : 1 }, 1, $@);
