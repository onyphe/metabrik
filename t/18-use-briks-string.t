use Test;
BEGIN { plan(tests => 11) }

ok(sub { eval("use Metabrik::String::Compress"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Parse"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Password"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Uri"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Base64"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Html"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Json"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Rot13"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Xml"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Hexa"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Random"); $@ ? 0 : 1 }, 1, $@);
