use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Format::Lncs"); $@ ? 0 : 1 }, 1, $@);
