#
# $Id$
#
package Plashy;
use strict;
use warnings;

our $VERSION = '0.11';

use base qw(Class::Gomor::Array);

our @AS = qw(
   log
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   if (! defined($self->log)) {
      die("[-] FATAL: you must pass a `log' attribute\n");
   }

   return $self;
}

1;

__END__
