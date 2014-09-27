#
# $Id$
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabricky',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_metabricky.org>',
   dist_version_from => 'lib/Metabricky.pm',
   requires => {
      'Class::Gomor' => '1.00',
      'Cwd' => 0,
      'Data::Dump' => 0,
      'Data::Dumper' => 0,
      'File::Find' => 0,
      'File::HomeDir' => 0,
      'IO::All' => 0,
      'IPC::Run' => 0,
      'Lexical::Persistence' => 0,
      'Module::Reload' => 0,
      'Term::ANSIColor' => 0,
   },
);

$builder->create_build_script;
