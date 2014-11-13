use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Server::Agent"); $@ ? 0 : 1 }, 1, $@);
