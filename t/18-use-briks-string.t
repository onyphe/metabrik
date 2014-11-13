use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::String::Compress"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Parse"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Password"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::String::Uri"); $@ ? 0 : 1 }, 1, $@);
