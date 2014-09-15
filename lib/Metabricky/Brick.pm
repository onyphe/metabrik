#
# $Id$
#
package Metabricky::Brick;
use strict;
use warnings;

use base qw(Class::Gomor::Hash);

our @AS = qw(
   debug
   inited
   bricks
   log
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      debug => 0,
      inited => 0,
      @_,
   );

   my $href = $self->default_values;
   for my $k (keys %$href) {
      $self->$k($href->{$k});
   }

   return $self;
}

sub default_values {
   return {};
}

sub init {
   my $self = shift;

   if ($self->inited) {
      return;
   }

   $self->inited(1);

   return $self;
}

sub require_attributes {
   my $self = shift;
   my (@attributes) = @_;

   $self->log->fatal("you must set attribute(s): ".join(', ', @attributes));
}

sub self {
   my $self = shift;

   return $self;
}

sub DESTROY {
   my $self = shift;

   return $self;
}

1;

__END__
