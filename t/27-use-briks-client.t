use Test;
BEGIN { plan(tests => 5) }

ok(sub { eval("use Metabrik::Client::Www"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Tcp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Whois"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Rsync"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Twitter"); $@ ? 0 : 1 }, 1, $@);
