use Test;
BEGIN { plan(tests => 34) }

ok(sub { eval("use Metabricky::Brick::Address::Netmask");     $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Audit::Dns");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Crypto::Aes");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Database::Cwe");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Database::Keystore");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Database::Nvd");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Database::Sqlite");     $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Database::Vfeed");      $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Encoding::Base64");     $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Example::Template");    $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::File::Create");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::File::Fetch");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::File::Find");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::File::Read");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::File::Write");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::File::Zip");            $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Http::Proxy");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Http::Www");            $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Http::Wwwutil");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Identify::Ssh");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Netbios::Name");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Network::Frame");       $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Remote::Ssh2");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Remote::Tcpdump");      $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Server::Agent");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Shell::History");       $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Shell::Meby");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Shell::Rc");            $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Shell::Script");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Ssdp::Ssdp");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::String::Gzip");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::System::Arp");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::System::Os");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::System::Route");        $@ ? 0 : 1 }, 1, $@);
