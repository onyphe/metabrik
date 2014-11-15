use Test;
BEGIN { plan(tests => 9) }

ok(sub { eval("use Metabrik::File::Compress"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Create"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Csv"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Fetch"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Find"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Read"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Write"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Xml"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Json"); $@ ? 0 : 1 }, 1, $@);
