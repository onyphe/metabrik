use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Worker::Fork"); $@ ? 0 : 1 }, 1, $@);
