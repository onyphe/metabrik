#
# $Id: Context.pm 94 2014-09-19 05:24:06Z gomor $
#
package Metabricky::Brick::Core::Context;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   log
   _lp
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Data::Dump;
use Data::Dumper;
use File::Find; # XXX: use Brick::Find
use Lexical::Persistence;

use Metabricky::Brick::Core::Global;
use Metabricky::Brick::Core::Log;

# Only used to avoid compile-time errors
my $__ctx = {};

{
   no warnings;

   # We rewrite the log accessor so we can fetch it from within context
   *log = sub {
      my $self = shift;

      # We can't use get() here, we would have a deep recursion
      # We can't use call() for the same reason

      my $lp = $self->_lp;

      my $save = $@;

      my $r;
      eval {
         $r = $lp->call(sub {
            return $__ctx->{log};
         });
      };
      if ($@) {
         chomp($@);
         die("[FATAL] core::context: log: $@\n");
      }

      $@ = $save;

      return $r;
   };
}

sub help {
   return [
      'run core::context load <brick>',
      'run core::context set <brick> <attribute> <value>',
      'run core::context get [ <brick> ] [ <attribute> ]',
      'run core::context run <brick> <command> [ <arg1 arg2 .. argN> ]',
      'run core::context loaded',
      'run core::context find_available',
      'run core::context update_available',
      'run core::context available',
      'run core::context status',
      'run core::context do <perl_code>',
      'run core::context call <perl_sub>',
   ];
}

sub revision {
   return '$Revision';
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   eval {
      my $lp = Lexical::Persistence->new;
      $lp->set_context(_ => {
         '$__ctx' => { },
         '$Context' => $self,
      });
      $lp->call(sub {
         my %args = @_;

         eval("use strict;");
         eval("use warnings;");

         $__ctx->{loaded} = {
            'core::context' => $args{self},
            'core::global' => Metabricky::Brick::Core::Global->new->init,
            'core::log' => Metabricky::Brick::Core::Log->new->init,
         };
         $__ctx->{available} = { };
         $__ctx->{set} = { };
         $__ctx->{log} = $__ctx->{loaded}->{'core::log'};

         # We don't use the log accessor to write the value because we wrote 
         # our own log accessor.
         $__ctx->{loaded}->{'core::context'}->{log} = $__ctx->{log};
         $__ctx->{loaded}->{'core::global'}->{log} = $__ctx->{log};

         return 1;
      }, self => $self);
      $self->_lp($lp);
   };
   if ($@) {
      chomp($@);
      die("[FATAL] core::context: new: unable to create context: $@\n");
   }
   
   return $self;
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $r = $self->update_available;
   if (! defined($r)) {
      return $self->log->fatal("init: unable to init Brick [core::context]");
   }

   return $self;
}

sub do {
   my $self = shift;
   my ($code, $dump) = @_;

   my $lp = $self->_lp;

   my $res;
   eval {
      if ($dump) {
         $self->debug && $self->log->debug("do: echo on");
         $res = Data::Dump::dump($lp->do($code));
      }
      else {
         $self->debug && $self->log->debug("do: echo off");
         $res = $lp->do($code);
      }
   };
   if ($@) {
      chomp($@);
      return $self->log->error("do: $@");
   }

   $self->debug && $self->log->debug("do: returned[".(defined($res) ? $res : 'undef')."]");

   return $res;
}

sub call {
   my $self = shift;
   my ($subref, %args) = @_;

   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->call($subref, %args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("call: $@");
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

sub find_available {
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

sub update_available {
   my $self = shift;

   my $h = $self->find_available;

   my $r = $self->call(sub {
      my %args = @_;

      return $__ctx->{available} = $args{available};
   }, available => $h);
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub load {
   my $self = shift;
   my ($brick) = @_;

   if (! defined($brick)) {
      return $self->log->error("run context load <brick>");
   }

   if ($brick !~ /^[a-z0-9]+::[a-z0-9]+$/) {
      return $self->log->error("invalid format for Brick [$brick]");
   }

   my ($category, $module) = split('::', $brick);

   $self->log->debug("category[$category]");
   $self->log->debug("module[$module]");

   $category = ucfirst($category);
   $module = ucfirst($module);
   $module = 'Metabricky::Brick::'.$category.'::'.$module;

   $self->log->debug("module[$module]");

   my $loaded = $self->loaded or return;
   if (exists($loaded->{$brick})) {
      return $self->log->error("Brick [$brick] already loaded");
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_module = $args{module};
      my $__lp_brick = $args{brick};

      eval("use $__lp_module;");
      if ($@) {
         chomp($@);
         die("load: unable to load Brick [$__lp_brick]: $@\n");
      }

      my $__lp_new = $__lp_module->new(
         bricks => $__ctx->{loaded},
         log => $__ctx->{log},
      );
      #$__lp_new->init; # No init now. We wait first run()
      if (! defined($__lp_new)) {
         die("load: unable to create Brick [$__lp_brick]\n");
      }

      return $__ctx->{loaded}->{$__lp_brick} = $__lp_new;
   }, module => $module, brick => $brick);
   if (! defined($r)) {
      return $self->log->error("load: unable to load Brick [$brick]");
   }

   return $r;
}

sub available {
   my $self = shift;

   my $r = $self->call(sub {
      return $__ctx->{available};
   });
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub loaded {
   my $self = shift;

   my $r = $self->call(sub {
      return $__ctx->{loaded};
   });
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub status {
   my $self = shift;

   my $available = $self->available or return;
   my $loaded = $self->loaded or return;

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

sub get {
   my $self = shift;
   my ($brick, $attribute) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};

      # Without arguments, we want to get all set attributes
      if (! defined($__lp_brick) && ! defined($__lp_attribute)) {
         return $__ctx->{set};
      }
      # With only one argument, we want to get set Attributes for the specified Brick
      elsif (defined($__lp_brick) && ! defined($__lp_attribute)) {
         if (! exists($__ctx->{loaded}->{$__lp_brick})) {
            die("get: Brick [$__lp_brick] not loaded\n");
         }

         return $__ctx->{set}->{$__lp_brick};
      }
      # Else we get one Brick Attribute
      else {
         if (! exists($__ctx->{loaded}->{$__lp_brick})) {
            die("get: Brick [$__lp_brick] not loaded\n");
         }

         if (! $__ctx->{loaded}->{$__lp_brick}->can($__lp_attribute)) {
            die("get: Brick [$__lp_brick] has no Attribute [$__lp_attribute]\n");
         }

         return $__ctx->{loaded}->{$__lp_brick}->$__lp_attribute;
      }

      return;
   }, brick => $brick, attribute => $attribute);
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub set {
   my $self = shift;
   my ($brick, $attribute, $value) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};
      my $__lp_value = $args{value};

      if (! exists($__ctx->{loaded}->{$__lp_brick})) {
         die("set: Brick [$__lp_brick] not loaded\n");
      }

      if (! $__ctx->{loaded}->{$__lp_brick}->can($__lp_attribute)) {
         die("set: Brick [$__lp_brick] has no Attribute [$__lp_attribute]\n");
      }

      #$__ctx->{loaded}->{$__lp_brick}->init; # No init when just setting an attribute
      $__ctx->{loaded}->{$__lp_brick}->$__lp_attribute($__lp_value);
      $__ctx->{set}->{$__lp_brick}->{$__lp_attribute} = $__lp_value;

      return $__lp_value;
   }, brick => $brick, attribute => $attribute, value => $value);
   if (! defined($r)) {
      return;
   }

   return $r;
}

sub run {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_command = $args{command};
      my @__lp_args = @{$args{args}};

      if (! exists($__ctx->{loaded}->{$__lp_brick})) {
         die("run: Brick [$__lp_brick] not loaded\n");
      }

      my $__lp_run = $__ctx->{loaded}->{$__lp_brick};
      if (! defined($__lp_run)) {
         die("run: Brick [$__lp_brick] not defined\n");
      }

      if (! $__ctx->{loaded}->{$__lp_brick}->can($__lp_command)) {
         die("run: Brick [$__lp_brick] has no Command [$__lp_command]\n");
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
