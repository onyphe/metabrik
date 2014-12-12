use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Crypto::Aes"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Crypto::Gpg"); $@ ? 0 : 1 }, 1, $@);
