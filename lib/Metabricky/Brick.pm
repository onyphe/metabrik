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

sub get_commands {
   my $self = shift;

   my @commands = ();
   {
      no strict 'refs';

      my @list = ( keys %{ref($self).'::'}, keys %{'Metabricky::Brick::'} );
      my $attributes = $self->get_attributes;

      for (@list) {
         next unless /^[a-z]/; # Brick Commands always begin with a minuscule
         next if /^cg[A-Z]/; # Class::Gomor stuff
         next if /^(?:a|b|import|init|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff
         my $is_attribute = 0;
         for my $attribute (@$attributes) {
            #print "_[$_] vs attr[$attribute]\n";
            if ($_ eq $attribute) {
               $is_attribute++;
               last;
            }
         }
         next if $is_attribute;
         push @commands, $_;
      }
   };

   return \@commands;
}

sub get_attributes {
   my $self = shift;

   my @attributes = ();
   {
      no strict 'refs';

      @attributes = ( @{ref($self).'::AS'}, @{'Metabricky::Brick::AS'} );
      my %h = map { $_ => 1 } @attributes;
      @attributes = sort { $a cmp $b } keys %h;
   };

   return \@attributes;
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

   return $self->log->fatal("you must set attribute(s): ".join(', ', @attributes));
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
