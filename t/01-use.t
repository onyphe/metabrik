use Test;
BEGIN { plan(tests => 8) }

ok(sub { eval("use Plashy");                 $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Log");            $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Log::Console");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Context");        $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Shell");          $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin");         $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Plugin::Global"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Plashy::Ext::Utils");     $@ ? 0 : 1 }, 1, $@);
