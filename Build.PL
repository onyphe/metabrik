#
# $Id$
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabrik::Repository',
   license => 'bsd',
   dist_author => 'GomoR <gomor_at_metabrik.org>',
   dist_version_from => 'lib/Metabrik/Repository.pm',
   requires => {
      'perl' => '5.6.1',
      'Metabrik' => '1.04',
   },
);

$builder->create_build_script;
