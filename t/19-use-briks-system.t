use Test;
BEGIN { plan(tests => 26) }

ok(sub { eval("use Metabrik::System::Docker"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::File"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Iocage"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Ezjail"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Freebsd::Pf"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Fsck"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Libvirt"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Mount"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Os"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Process"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Service"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Ubuntu::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Ubuntu::Service"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Ubuntu::User"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Debian::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Debian::Service"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Debian::User"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Virtualbox"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Gphotofs"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Centos::Package"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Centos::Service"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Centos::User"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Netstat"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::System::Route"); $@ ? 0 : 1 }, 1, $@);
