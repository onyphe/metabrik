use Test;
BEGIN { plan(tests => 26) }

ok(sub { eval("Plashy::Brick::Aes");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Agent");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Arp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Auditdns");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Base64");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Cwe");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Fetch");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Find");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Global");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Httpproxy");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Keystore");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Nbname");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Netframe");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Netmask");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Nvd");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Route");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Slurp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Sqlite");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Ssdp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Ssh2");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Ssh");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Template");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Vfeed");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Www");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Wwwutil");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Plashy::Brick::Zip");   $@ ? 0 : 1 }, 1, $@);
