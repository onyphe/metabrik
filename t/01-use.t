use Test;
BEGIN { plan(tests => 8) }

ok(sub { eval("use Metabricky");                $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Log");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Log::Console");  $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Context");       $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Shell");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Brick::Global"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabricky::Ext::Utils");    $@ ? 0 : 1 }, 1, $@);
