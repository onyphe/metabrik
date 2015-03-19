#
# $Id$
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabrik::Repository',
   VERSION_FROM => 'lib/Metabrik/Repository.pm',
   LICENSE => 'bsd',
   ABSTRACT_FROM => 'lib/Metabrik/Repository.pm',
   AUTHOR => 'GomoR <gomor_at_metabrik.org>',
   PREREQ_PM => {
      'Metabrik' => '1.08',
   },
   MIN_PERL_VERSION => '5.6.1',
);
