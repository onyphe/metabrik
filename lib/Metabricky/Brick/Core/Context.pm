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

sub revision {
   return '$Revision$';
}

sub help {
   return {
      'run:load' => '<brick>',
      'run:set' => '<brick> <attribute> <value>',
      'run:get' => '<brick> <attribute>',
      'run:run' => '<brick> <command> [ <arg1 arg2 .. argN> ]',
      'run:loaded' => '',
      'run:find_available' => '',
      'run:update_available' => '',
      'run:available' => '',
      'run:status' => '',
      'run:do' => '<perl_code>',
      'run:call' => '<perl_sub>',
   };
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

   if (! defined($code)) {
      return $self->log->info($self->help_run('do'));
   }

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

   if (! defined($subref)) {
      return $self->log->info($self->help_run('call'));
   }

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
      return $self->log->error("update_available: unable to get available Bricks");
   }

   return $r;
}

sub load {
   my $self = shift;
   my ($brick) = @_;

   if (! defined($brick)) {
      return $self->log->info($self->help_run('load'));
   }

   my $repository = '';
   my $category = '';
   my $module = '';

   if ($brick =~ /^[a-z0-9]+::[a-z0-9]+$/) {
      ($category, $module) = split('::', $brick);
   }
   elsif ($brick =~ /^[a-z0-9]+::[a-z0-9]+::[a-z0-9]+$/) {
      ($repository, $category, $module) = split('::', $brick);
   }
   else {
      return $self->log->error("load: invalid format for Brick [$brick]");
   }

   $self->log->debug("repository[$repository]");
   $self->log->debug("category[$category]");
   $self->log->debug("module[$module]");

   $category = ucfirst($category);
   $module = ucfirst($module);
   $module = 'Metabricky::Brick::'.$category.'::'.$module;

   $self->log->debug("module2[$module]");

   my $loaded = $self->loaded;
   if (! defined($loaded)) {
      $self->debug && $self->log->debug("load: unable to get loaded Bricks");
      return;
   }
   if (exists($loaded->{$brick})) {
      return $self->log->error("load: Brick [$brick] already loaded");
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
      return $self->log->error("available: unable to get available Bricks");
   }

   return $r;
}

sub loaded {
   my $self = shift;

   my $r = $self->call(sub {
      return $__ctx->{loaded};
   });
   if (! defined($r)) {
      return $self->log->error("loaded: unable to get loaded Bricks");
   }

   return $r;
}

sub status {
   my $self = shift;

   my $available = $self->available;
   if (! defined($available)) {
      $self->debug && $self->log->debug("status: unable to get available Bricks");
      return { loaded => [], notloaded => [] };
   }

   my $loaded = $self->loaded;
   if (! defined($loaded)) {
      $self->debug && $self->log->debug("status: unable to get loaded Bricks");
      return { loaded => [], notloaded => [] };
   }

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

sub set {
   my $self = shift;
   my ($brick, $attribute, $value) = @_;

   if (! defined($brick) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info($self->help_run('set'));
   }

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

      $__ctx->{loaded}->{$__lp_brick}->$__lp_attribute($__lp_value);
      $__ctx->{set}->{$__lp_brick}->{$__lp_attribute} = $__lp_value;

      return $__lp_value;
   }, brick => $brick, attribute => $attribute, value => $value);
   if (! defined($r)) {
      return $self->log->error("set: unable to set Attribute");
   }

   return $r;
}

sub get {
   my $self = shift;
   my ($brick, $attribute) = @_;

   if (! defined($brick) || ! defined($attribute)) {
      return $self->log->info($self->help_run('get'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};

      if (! exists($__ctx->{loaded}->{$__lp_brick})) {
         die("get: Brick [$__lp_brick] not loaded\n");
      }

      if (! $__ctx->{loaded}->{$__lp_brick}->can($__lp_attribute)) {
         die("get: Brick [$__lp_brick] has no Attribute [$__lp_attribute]\n");
      }

      my $__lp_value = $__ctx->{loaded}->{$__lp_brick}->$__lp_attribute || 'undef';

      return $__lp_value;
   }, brick => $brick, attribute => $attribute);
   if (! defined($r)) {
      return $self->log->error("get: unable to get Attribute");
   }

   return $r;
}

sub run {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   if (! defined($brick) || ! defined($command)) {
      return $self->log->info($self->help_run('run'));
   }

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
      return $self->log->error("run: unable to run Command");
   }

   return $r;
}

1;

__END__
