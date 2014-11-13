use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Crypto::Aes"); $@ ? 0 : 1 }, 1, $@);
