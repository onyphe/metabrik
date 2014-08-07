use Test;
BEGIN { plan(tests => 16) }

ok(sub { eval("use Plashy");                 $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Log");            $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Global"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Shell");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Ext::Utils");     $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin");         $@ ? 0 : 1 }, 1, $@);

ok(sub { eval("use Plashy::Plugin::Netmask");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Nbname");    $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Template");  $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Httpproxy"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Netframe");  $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Slurp");     $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Ssh2");      $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Www");       $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Vfeed");     $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Wwwutil");   $@ ? 0 : 1 }, 1, $@);
