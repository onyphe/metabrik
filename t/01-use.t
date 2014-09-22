use Test;
BEGIN { plan(tests => 7) }

ok(sub { eval("use Metabricky");                        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick");                 $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Core::Context");  $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Core::Global");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Core::Log");      $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Ext::Shell");            $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Ext::Utils");            $@ ? 0 : 1 }, 1, $@);
