use Test;
BEGIN { plan(tests => 7) }

ok(sub { eval("use Metabrik::Encoding::Base64"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Encoding::Html"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Encoding::Json"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Encoding::Rot13"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Encoding::Utf8"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Encoding::Xml"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Encoding::Hexa"); $@ ? 0 : 1 }, 1, $@);
