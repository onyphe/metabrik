use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Server::Agent"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Http"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Server::Dns"); $@ ? 0 : 1 }, 1, $@);
