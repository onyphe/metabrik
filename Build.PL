#
# $Id$
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabrik',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_metabrik.org>',
   dist_version_from => 'lib/Metabrik.pm',
   requires => {
      'File::HomeDir' => 0,
      'IPC::Run' => 0,
   },
   configure_requires => {
      'Module::Build' => 0.42,
   },
);

$builder->create_build_script;
