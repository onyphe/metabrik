use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Image::Jpg"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Image::Exif"); $@ ? 0 : 1 }, 1, $@);
