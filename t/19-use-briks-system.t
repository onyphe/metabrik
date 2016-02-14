use Test;
BEGIN { plan(tests => 14) }

ok(sub { eval("use Metabrik::System::Docker"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::File"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Iocage"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Jail"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Pf"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Libvirt"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Os"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Process"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Service"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Ubuntu::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Ubuntu::User"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Virtualbox"); $@ ? 0 : 1 }, 1, $@);
