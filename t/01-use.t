use Test;
BEGIN { plan(tests => 6) }

ok(sub { eval("use Metabrik");                       $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik");                 $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Core::Context");  $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Core::Global");   $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Core::Log");      $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Core::Shell");    $@ ? 0 : 1 }, 1, $@);
