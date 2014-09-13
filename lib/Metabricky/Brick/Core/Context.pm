#
# $Id$
#
package Metabricky::Brick::Core::Context;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   log
   _lp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Data::Dump;
use Data::Dumper;
use File::Find; # XXX: use Brick::Find
use Lexical::Persistence;

# Only used to avoid compile-time errors
my $__ctx = {};

sub help {
   print "run core::context do <perl_code>\n";
   print "run core::context call <perl_sub>\n";
   print "run core::context get <attribute>\n";
   print "run core::context get_available\n";
   print "run core::context get_loaded\n";
   print "run core::context update_available_bricks\n";
   print "run core::context get_loaded_bricks\n";
   print "run core::context get_set_attributes\n";
   print "run core::context set_brick_attribute <brick> <attribute> <value>\n";
   print "run core::context execute_brick_command <brick> <command> [ <arg1 arg2 .. argN> ]\n";
}

#sub default_values {
   #my $self = shift;

   #return {
   #};
#}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $log = $self->log;
   if (! defined($log)) {
      die("[FATAL] core::context: new: you have to give a `log' object\n");
   }

   eval {
      my $lp = Lexical::Persistence->new;
      $lp->set_context(_ => { '$__ctx' => { } });
      $lp->call(sub {
         my %args = @_;

         eval("use strict;");
         eval("use warnings;");

         $__ctx->{loaded_bricks} = {
            'core::context' => $args{self},
         };
         $__ctx->{available_bricks} = { };
         $__ctx->{set_attributes} = { };

         return 1;
      }, self => $self);
      $self->_lp($lp);
   };
   if ($@) {
      chomp($@);
      $log->fatal("core::context: new: unable to initialize context: $@");
   }
   
   return $self;
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   $self->set_available_bricks
      or $self->log->fatal("core::context: init: unable to set_available_bricks");

   return $self;
}

sub do {
   my $self = shift;
   my ($code) = @_;

   my $log = $self->log;
   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->do($code);
   };
   if ($@) {
      chomp($@);
      $log->error("core::context: do: $@");
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
      $log->error("core::context: call: $@");
      return;
   }

   return $res;
}


# XXX: to replace with Brick::Find
my @available = ();

sub _find_bricks {
   if ($File::Find::dir =~ /Metabricky\/Brick/ && /.pm$/) {
      #print "DEBUG found[$File::Find::dir/$_\n";
      (my $category = lc($File::Find::dir)) =~ s/^.*\/metabricky\/brick\/?(.*?)$/$1/;
      $category =~ s/\//::/g;
      (my $brick = lc($_)) =~ s/.pm$//;
      #print "DEBUG brick[$brick] [$category]\n";
      if (length($category)) {
         push @available, $category.'::'.$brick;
      }
      else {
         push @available, $brick;
      }
   }
}

sub find_available_bricks {
   my $self = shift;

   {
      no warnings 'File::Find';
      my @dirs = ();
      # We skip dot directories
      for my $dir (@INC) {
         push @dirs, $dir unless $dir =~ /^\./;
      }
      find(\&_find_bricks, @dirs);
   };

   my %h = map { $_ => 1 } @available;

   return \%h;
}

sub set_available_bricks {
   my $self = shift;

   my $h = $self->find_available_bricks;

   my $r = $self->call(sub {
      my %args = @_;

      return $__ctx->{available_bricks} = $args{available_bricks};
   }, available_bricks => $h);
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub load_brick {
   my $self = shift;
   my ($brick) = @_;

   # XXX: use Module::Loaded (core) or Module::Load/Unload or Module::Reload?
   my $log = $self->log;

   if (! defined($brick)) {
      $log->error("run context load <brick>");
      return;
   }

   #print "DEBUG brick[$brick]\n";

   my ($category, $module) = split('::', $brick);
   # Brick has a category
   # XXX: when migration to categorised Bricks is finished, we can remove this check:
   #      Every Brick will have a category.
   if (defined($module)) {
      #print "DEBUG category[$category] module[$module]\n";
      $category = ucfirst($category);
      $module = ucfirst($module);
      $module = 'Metabricky::Brick::'.$category.'::'.$module;
      #print "DEBUG module[$module]\n";
   }
   # Brick has no category
   else {
      $module = ucfirst($category);
      $module = 'Metabricky::Brick::'.$module;
   }

   my $loaded_bricks = $self->get_loaded_bricks or return;
   if (exists($loaded_bricks->{$brick})) {
      $log->error("Brick [$brick] already loaded");
      return;
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_module = $args{module};
      my $__lp_brick = $args{brick};

      eval("use $__lp_module;");
      if ($@) {
         chomp($@);
         die("unable to load Brick [$__lp_brick]: $@\n");
      }

      my $__lp_new = $__lp_module->new(
         bricks => $__ctx->{loaded_bricks},
      );
      #$__lp_new->init; # No init now. We wait first run()

      return $__ctx->{loaded_bricks}->{$__lp_brick} = $__lp_new;
   }, module => $module, brick => $brick);
   if (! defined($r)) {
      $log->error("core::context: load_brick: unable to load Brick [$brick]");
      return;
   }

   return $r;
}

sub get_available_bricks {
   my $self = shift;

   my $r = $self->call(sub {
      return $__ctx->{available_bricks};
   });
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub get_loaded_bricks {
   my $self = shift;

   my $r = $self->call(sub {
      return $__ctx->{loaded_bricks};
   });
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub get_set_attributes {
   my $self = shift;

   my $r = $self->call(sub {
      return $__ctx->{set_attributes};
   });
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub get_status_bricks {
   my $self = shift;

   my $available = $self->get_available_bricks or return;
   my $loaded = $self->get_loaded_bricks or return;

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

sub get_brick_attribute {
   my $self = shift;
   my ($brick, $attribute) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};

      if (! exists($__ctx->{loaded_bricks}->{$__lp_brick})) {
         die("Brick [$__lp_brick] not loaded\n");
      }

      if (! $__ctx->{loaded_bricks}->{$__lp_brick}->can($__lp_attribute)) {
         die("Brick [$__lp_brick] has no Attribute [$__lp_attribute]\n");
      }

      return $__ctx->{loaded_bricks}->{$__lp_brick}->$__lp_attribute;
   }, brick => $brick, attribute => $attribute);
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub set_brick_attribute {
   my $self = shift;
   my ($brick, $attribute, $value) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};
      my $__lp_value = $args{value};

      if (! exists($__ctx->{loaded_bricks}->{$__lp_brick})) {
         die("Brick [$__lp_brick] not loaded\n");
      }

      if (! $__ctx->{loaded_bricks}->{$__lp_brick}->can($__lp_attribute)) {
         die("Brick [$__lp_brick] has no Attribute [$__lp_attribute]\n");
      }

      #$__ctx->{loaded_bricks}->{$__lp_brick}->init; # No init when just setting an attribute
      $__ctx->{loaded_bricks}->{$__lp_brick}->$__lp_attribute($__lp_value);
      $__ctx->{set_attributes}->{$__lp_brick}->{$__lp_attribute} = $__lp_value;

      return $__lp_value;
   }, brick => $brick, attribute => $attribute, value => $value);
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub execute_brick_command {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_command = $args{command};
      my @__lp_args = @{$args{args}};

      if (! exists($__ctx->{loaded_bricks}->{$__lp_brick})) {
         die("Brick [$__lp_brick] not loaded\n");
      }

      my $__lp_run = $__ctx->{loaded_bricks}->{$__lp_brick};
      if (! defined($__lp_run)) {
         die("Brick [$__lp_brick] not defined\n");
      }

      if (! $__ctx->{loaded_bricks}->{$__lp_brick}->can($__lp_command)) {
         die("Brick [$__lp_brick] has no Command [$__lp_command]\n");
      }

      $__lp_run->init; # Will init() only if not already done

      return $_ = $__lp_run->$__lp_command(@__lp_args);
   }, brick => $brick, command => $command, args => \@args);
   if (! defined($r)) {
      return;
   }

   return $r;
}

1;

__END__
