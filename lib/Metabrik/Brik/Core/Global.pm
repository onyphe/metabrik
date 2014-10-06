#
# $Id$
#
# core::global Brik
#
package Metabrik::Brik::Core::Global;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return [ qw(
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
   )];
}

sub declare_tags {
   return [ qw(core) ];
}

sub require_modules {
   return {
      'Metabrik' => [],
   };
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
      'run:metabrik_version' => '',
   };
}

sub metabrik_version {
   my $self = shift;

   return $Metabrik::VERSION;
}

1;

__END__
