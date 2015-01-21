use Test;
BEGIN { plan(tests => 10) }

ok(sub { eval("use Metabrik::Database::Cwe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Keystore"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Nvd"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Sqlite"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Vfeed"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Redis"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Elasticsearch"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Sinfp3"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Ripe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Rir"); $@ ? 0 : 1 }, 1, $@);
