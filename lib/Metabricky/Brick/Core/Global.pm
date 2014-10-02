#
# $Id: Global.pm 89 2014-09-17 20:29:29Z gomor $
#
# Global brick
#
package Metabricky::Brick::Core::Global;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   input
   output
   db
   file
   uri
   target
   ctimeout
   rtimeout
   datadir
   username
   hostname
   homedir
   port
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub require_modules {
   return {
      'Metabricky' => [],
   };
}

sub revision {
   return '$Revision$';
}

sub default_values {
   return {
      input => '/tmp/input.txt',
      output => '/tmp/output.txt',
      db => '/tmp/db.db',
      file => '/tmp/file.txt',
      uri => 'http://www.example.com',
      target => 'localhost',
      ctimeout => 5,
      rtimeout => 5,
      datadir => '/tmp',
      username => $ENV{USER} || 'root',
      hostname => 'localhost',
      homedir => $ENV{HOME} || '/tmp',
      port => 80,
   };
}

sub help {
   return {
      'set:input' => '<input>',
      'set:output' => '<output>',
      'set:db' => '<db>',
      'set:file' => '<file>',
      'set:uri' => '<uri>',
      'set:target' => '<target>',
      'set:ctimeout' => '<connection_timeout>',
      'set:rtimeout' => '<read_timeout>',
      'set:datadir' => '<directory>',
      'set:username' => '<username>',
      'set:hostname' => '<hostname>',
      'set:port' => '<port>',
      'set:homedir' => '<directory>',
      'run:metabricky_version' => '',
   };
}

sub metabricky_version {
   my $self = shift;

   return $Metabricky::VERSION;
}

1;

__END__
