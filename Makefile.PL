#
# $Id$
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabrik',
   VERSION_FROM => 'lib/Metabrik.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Metabrik.pm',
   AUTHOR => 'GomoR <gomor_at_metabrik.org>',
   PREREQ_PM => {
      'File::HomeDir' => 0,  
      'IPC::Run' => 0,
   },
);
