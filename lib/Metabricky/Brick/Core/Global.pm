#
# $Id$
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
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      datadir => '/tmp',
      @_,
   );

   return $self;
}

sub help {
   return [
      'set core::global input <input>',
      'set core::global output <output>',
      'set core::global db <db>',
      'set core::global file <file>',
      'set core::global uri <uri>',
      'set core::global target <target>',
      'set core::global ctimeout <connection_timeout>',
      'set core::global rtimeout <read_timeout>',
      'set core::global datadir <directory>',
   ];
}

1;

__END__
