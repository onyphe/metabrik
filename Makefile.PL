#
# $Id: Makefile.PL 90 2014-09-17 20:38:31Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabricky',
   VERSION_FROM => 'lib/Metabricky.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Metabricky.pm',
   AUTHOR => 'GomoR <gomor-cpan_at_gomor.org>',
   PREREQ_PM => {
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
