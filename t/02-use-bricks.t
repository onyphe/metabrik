use Test;
BEGIN { plan(tests => 26) }

ok(sub { eval("MetaBricky::Brick::Aes");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Agent");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Arp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Auditdns");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Base64");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Cwe");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Fetch");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Find");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Global");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Httpproxy");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Keystore");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Nbname");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Netframe");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Netmask");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Nvd");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Route");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Slurp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Sqlite");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Ssdp");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Ssh2");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Ssh");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Template");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Vfeed");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Www");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Wwwutil");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("MetaBricky::Brick::Zip");   $@ ? 0 : 1 }, 1, $@);
