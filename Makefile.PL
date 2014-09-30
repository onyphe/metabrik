#
# $Id$
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabricky',
   VERSION_FROM => 'lib/Metabricky.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Metabricky.pm',
   AUTHOR => 'GomoR <gomor_at_metabricky.org>',
   PREREQ_PM => {
      'File::HomeDir' => 0,  
      'IPC::Run' => 0,
   },
);
