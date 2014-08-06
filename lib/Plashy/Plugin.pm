#
# $Id$
#
package Plashy::Plugin;
use strict;
use warnings;

use base qw(Class::Gomor::Array);

our @AS = qw(
   global
   debug
   inited
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      debug => 0,
      inited => 0,
      @_,
   );

   return $self;
}

sub init {
   my $self = shift;

   if ($self->inited) {
      return;
   }

   $self->inited(1);

   return $self;
}

sub require_variables {
   my $self = shift;
   my (@vars) = @_;

   die("you must set variable(s): ".join(', ', @vars)."\n");
}

sub DESTROY {
   my $self = shift;

   return $self;
}

1;

__END__
