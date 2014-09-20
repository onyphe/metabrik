#
# $Id: Brick.pm 93 2014-09-18 06:06:28Z gomor $
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
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      debug => 0,
      inited => 0,
      @_,
   );

   my $default_values = $self->default_values;
   for my $k (keys %$default_values) {
      $self->$k($default_values->{$k});
   }

   my $modules = $self->require_modules;
   for my $module (@$modules) {
      eval("use $module");
      if ($@) {
         chomp($@);
         return $self->log->error("new: you have to install Module [$module]");
      }
   }

   return $self;
}

sub revision {
   return 1;
}

sub version {
   my $self = shift;

   my $revision = $self->revision;
   my ($version) = $revision =~ /(\d+)/;

   # Version 1 of the API
   return "1.$version";
}

sub default_values {
   return {};
}

sub name {
   my $self = shift;

   my $module = lc(ref($self));
   $module =~ s/^metabricky::brick:://;

   return $module;
}

sub repository {
   my $self = shift;

   my $name = $self->name;

   my @toks = split('::', $name);

   # No repository defined
   if (@toks == 2) {
      return 'main';
   }
   elsif (@toks > 2) {
      my ($repository) = $name =~ /^(.*?)::.*/;
      return $repository;
   }

   return $self->log->fatal("repository: no Repository found");
}

sub category {
   my $self = shift;

   my $name = $self->name;

   my @toks = split('::', $name);

   # No repository defined
   if (@toks == 2) {
      my ($category) = $name =~ /^(.*?)::.*/;
      return $category;
   }
   elsif (@toks > 2) {
      my ($category) = $name =~ /^.*?::(.*?)::.*/;
      return $category;
   }

   # Error, category not found
   return $self->log->fatal("category: no Category found");
}

sub commands {
   my $self = shift;

   my @commands = ();
   {
      no strict 'refs';

      my @list = ( keys %{ref($self).'::'}, keys %{'Metabricky::Brick::'} );
      my $attributes = $self->attributes;

      for (@list) {
         next unless /^[a-z]/; # Brick Commands always begin with a minuscule
         next if /^cg[A-Z]/; # Class::Gomor stuff
         next if /^_/; # Internal stuff
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

sub attributes {
   my $self = shift;

   my @attributes = ();
   {
      no strict 'refs';

      my @as = ( @{ref($self).'::AS'}, @{'Metabricky::Brick::AS'} );
      my %h = map { $_ => 1 } @as;
      for (sort { $a cmp $b } keys %h) {
         next if /^_/; # Internal stuff
         push @attributes, $_;
      }
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

sub require_modules {
   return [];
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
