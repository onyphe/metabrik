use Test;
BEGIN { plan(tests => 8) }

ok(sub { eval("use MetaBricky");                $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use MetaBricky::Log");           $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use MetaBricky::Log::Console");  $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use MetaBricky::Context");       $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use MetaBricky::Shell");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use MetaBricky::Brick");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use MetaBricky::Brick::Global"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use MetaBricky::Ext::Utils");    $@ ? 0 : 1 }, 1, $@);
