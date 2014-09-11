#
# $Id$
#
package Metabricky::Brick::Core::Context;
use strict;
use warnings;

use base qw(Class::Gomor::Hash);

our @AS = qw(
   log
   shell
   global
   _lp
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Lexical::Persistence;
use Metabricky::Brick::Core::Global;

# Only used to avoid compile-time issue
my $global = {};

sub help {
   print "run context do <perl_code>\n";
   print "run context call <perl_sub>\n";
   print "run context global_get <attribute>\n";
   print "run context global_get_available\n";
   print "run context global_get_loaded\n";
   print "run context global_update_available_bricks\n";
   print "run context global_get_loaded_bricks\n";
   print "run context global_get_set_attributes\n";
   print "run context global_set_brick_attribute <brick> <attribute> <value>\n";
   print "run context execute_brick_command <brick> <command> [ <arg1 arg2 .. argN> ]\n";
}

#sub default_values {
#   my $self = shift;

#   return {
#      attribute1 => 'value1',
#   };
#}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $log = $self->log;
   if (! defined($log)) {
      die("[FATAL] Core::Context::new: you have to give a `log' object\n");
   }

   my $shell = $self->shell;
   if (! defined($shell)) {
      $log->fatal("Core::Context::new: you have to give a `shell' object");
   }

   eval {
      my $lp = Lexical::Persistence->new;
      $lp->set_context(_ => {
         '$global' => Metabricky::Brick::Core::Global->new(shell => $shell)->init,
      });
      $self->_lp($lp);
   };
   if ($@) {
      chomp($@);
      $log->fatal("Core::Context::new: can't initialize Brick global: $@");
   }
   
   $self->do("use strict;");
   $self->do("use warnings;");
   $self->do("use Data::Dumper;");
   $self->do("use Data::Dump;");

   return $self;
}

sub do {
   my $self = shift;
   my ($code) = @_;

   my $log = $self->log;
   my $lp = $self->_lp;

   my $echo = $self->global_get('echo');

   my $res;
   eval {
      if ($echo) {
         $res = Data::Dump::dump($lp->do($code));
         print "$res\n";
      }
      else {
         $res = $lp->do($code);
      }
   };
   if ($@) {
      chomp($@);
      $log->error("Context::do: $@");
      return;
   }

   return $res;
}

sub call {
   my $self = shift;
   my ($subref, %args) = @_;

   my $log = $self->log;
   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->call($subref, %args);
   };
   if ($@) {
      chomp($@);
      $log->error("Context::call: $@");
      return;
   }

   return $res;
}

sub global_load {
   my $self = shift;
   my ($brick) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};

      return $global->load($__lp_brick);
   }, brick => $brick);

   return $r;
}

sub global_get {
   my $self = shift;
   my ($attribute) = @_;

   my $value = $self->call(sub {
      my %args = @_;

      my $__lp_attribute = $args{attribute};
      my $__lp_value = $global->$__lp_attribute;

      if (! $global->can($__lp_attribute)) {
         die("Brick [global] has no Attribute [$attribute]\n");
      }

      return $__lp_value;
   }, attribute => $attribute);

   return $value;
}

sub global_get_available {
   my $self = shift;

   return $self->global_get('available');
}

sub global_get_loaded {
   my $self = shift;

   return $self->global_get('loaded');
}

sub global_update_available_bricks {
   my $self = shift;

   my $r = $self->call(sub { $global->update_available_bricks; })
      or return;

   return $r;
}

sub global_get_loaded_bricks {
   my $self = shift;

   my $available = $self->global_get_available or return;
   my $loaded = $self->global_get_loaded or return;

   my @loaded = ();
   my @notloaded = ();

   for my $k (sort { $a cmp $b } keys %$available) {
      exists($loaded->{$k}) ? push @loaded, $k : push @notloaded, $k;
   }

   return {
      loaded => \@loaded,
      notloaded => \@notloaded,
   };
}

sub global_get_set_attributes {
   my $self = shift;

   return $self->global_get('set');
}

sub global_set_brick_attribute {
   my $self = shift;
   my ($brick, $attribute, $value) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};
      my $__lp_value = $args{value};

      if (! exists($global->loaded->{$__lp_brick})) {
         die("Brick [$__lp_brick] not loaded\n");
      }

      if (! $global->loaded->{$__lp_brick}->can($__lp_attribute)) {
         die("Brick [$__lp_brick] has no Attribute [$__lp_attribute]\n");
      }

      #$global->loaded->{$__lp_brick}->init; # No init when just setting an attribute
      $global->loaded->{$__lp_brick}->$__lp_attribute($__lp_value);
      $global->set->{$__lp_brick}->{$__lp_attribute} = $__lp_value;

      return $__lp_value;
   }, brick => $brick, attribute => $attribute, value => $value);
   if (! defined($r)) {
      return;
   }

   return 1;
}

sub execute_brick_command {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_command = $args{command};
      my @__lp_args = @{$args{args}};

      if (! exists($global->loaded->{$__lp_brick})) {
         die("Brick [$__lp_brick] not loaded\n");
      }

      my $__lp_run = $global->loaded->{$__lp_brick};
      if (! defined($__lp_run)) {
         die("Brick [$__lp_brick] not defined\n");
      }

      if (! $global->loaded->{$__lp_brick}->can($__lp_command)) {
         die("Brick [$__lp_brick] has no Command [$__lp_command]\n");
      }

      $__lp_run->init; # Will init() only if not already done

      return $_ = $__lp_run->$__lp_command(@__lp_args);
   }, brick => $brick, command => $command, args => \@args);
   if (! defined($r)) {
      return;
   }

   return 1;
}

1;

__END__
