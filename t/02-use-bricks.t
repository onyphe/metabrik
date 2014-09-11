use Test;
BEGIN { plan(tests => 25) }

ok(sub { eval("Metabricky::Brick::Aes");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Agent");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Arp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Auditdns");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Base64");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Cwe");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Fetch");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Find");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Httpproxy");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Identify::Ssh");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Keystore");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Nbname");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Netframe");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Netmask");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Nvd");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Route");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Slurp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Sqlite");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Ssdp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Ssh2");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Template");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Vfeed");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Www");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Wwwutil");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("Metabricky::Brick::Zip");   $@ ? 0 : 1 }, 1, $@);
