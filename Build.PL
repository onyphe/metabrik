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
      'File::HomeDir' => 0,
      'IPC::Run' => 0,
   },
);

$builder->create_build_script;
