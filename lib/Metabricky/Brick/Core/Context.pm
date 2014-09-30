#
# $Id: Context.pm 94 2014-09-19 05:24:06Z gomor $
#
package Metabricky::Brick::Core::Context;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
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
my $CTX;

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
            return $CTX->{log};
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
      'run:is_loaded' => '<brick>',
      'run:find_available' => '',
      'run:update_available' => '',
      'run:available' => '',
      'run:is_available' => '<brick>',
      'run:status' => '',
      'run:variables' => '',
   };
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   eval {
      my $lp = Lexical::Persistence->new;
      $lp->set_context(_ => {
         '$CTX' => 'undef',
         '$SET' => 'undef',
         '$GET' => 'undef',
         '$RUN' => 'undef',
         '$ERR' => 'undef',
         '$MSG' => 'undef',
         '$RES' => 'undef',
      });
      $lp->call(sub {
         my %args = @_;

         $CTX = $args{self};

         $CTX->{loaded} = {
            'core::context' => $CTX,
            'core::global' => Metabricky::Brick::Core::Global->new->init,
            'core::log' => Metabricky::Brick::Core::Log->new->init,
         };
         $CTX->{available} = { };
         $CTX->{set} = { };
         $CTX->{log} = $CTX->{loaded}->{'core::log'};
         $CTX->{global} = $CTX->{loaded}->{'core::global'};

         # We don't use the log accessor to write the value because we wrote 
         # our own log accessor.
         $CTX->{loaded}->{'core::context'}->{log} = $CTX->{log};
         $CTX->{loaded}->{'core::global'}->{log} = $CTX->{log};

         # When new() was done, bricks was empty. We fix that here.
         $CTX->{loaded}->{'core::global'}->{context} = $CTX;
         $CTX->{loaded}->{'core::log'}->{context} = $CTX;

         # We did put log and context in Attributes, why not also put global:
         $CTX->{loaded}->{'core::context'}->{global} = $CTX->{global};
         $CTX->{loaded}->{'core::log'}->{global} = $CTX->{global};

         my $ERR = 0;

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
      return $self->log->error("init: unable to init Brick [core::context]: update_available failed");
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

sub lookup {
   my $self = shift;
   my ($varname) = @_;

   if (! defined($varname)) {
      return $self->log->error($self->help_run('lookup'));
   }

   my $res = $self->call(sub {
      my %args = @_;

      my $__ctx_varname = $args{varname};

      return $CTX->_lp->{context}->{_}->{$__ctx_varname};
   }, varname => $varname);

   $self->debug && $self->log->debug("lookup: [$varname] = [".substr($res, 0, 128)."..]");

   return $res;
}

sub variables {
   my $self = shift;

   my $res = $self->call(sub {
      my @__ctx_variables = ();

      for my $__ctx_variable (keys %{$CTX->_lp->{context}->{_}}) {
         next if $__ctx_variable !~ /^\$/;
         next if $__ctx_variable =~ /^\$_/;

         push @__ctx_variables, $__ctx_variable;
      }

      return \@__ctx_variables;
   });

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

      return $CTX->{available} = $args{available};
   }, available => $h);

   return $r;
}

sub load {
   my $self = shift;
   my ($brick) = @_;

   if (! defined($brick)) {
      return $self->log->info($self->help_run('load'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brick = $args{brick};

      my $ERR = 0;

      my $__ctx_brick_repository = '';
      my $__ctx_brick_category = '';
      my $__ctx_brick_module = '';

      if ($__ctx_brick =~ /^[a-z0-9]+::[a-z0-9]+$/) {
         ($__ctx_brick_category, $__ctx_brick_module) = split('::', $__ctx_brick);
      }
      elsif ($__ctx_brick =~ /^[a-z0-9]+::[a-z0-9]+::[a-z0-9]+$/) {
         ($__ctx_brick_repository, $__ctx_brick_category, $__ctx_brick_module) = split('::', $__ctx_brick);
      }
      else {
         $ERR = 1;
         my $MSG = "load: invalid format for Brick [$__ctx_brick]";
         die("$MSG\n");
      }

      if ($CTX->debug) {
         $CTX->log->debug("repository[$__ctx_brick_repository]");
         $CTX->log->debug("category[$__ctx_brick_category]");
         $CTX->log->debug("module[$__ctx_brick_module]");
      }

      $__ctx_brick_repository = ucfirst($__ctx_brick_repository);
      $__ctx_brick_category = ucfirst($__ctx_brick_category);
      $__ctx_brick_module = ucfirst($__ctx_brick_module);

      my $__ctx_module = 'Metabricky::Brick::'.(length($__ctx_brick_repository) ? $__ctx_brick_repository.'::' : '').$__ctx_brick_category.'::'.$__ctx_brick_module;

      $CTX->debug && $CTX->log->debug("module2[$__ctx_brick_module]");

      if ($CTX->is_loaded($__ctx_brick)) {
         $ERR = 1;
         my $MSG = "load: Brick [$__ctx_brick] already loaded";
         die("$MSG\n");
      }

      eval("require $__ctx_module;");
      if ($@) {
         chomp($@);
         $ERR = 1;
         my $MSG = "load: unable to use module [$__ctx_module]: $@";
         die("$MSG\n");
      }

      my $__ctx_new = $__ctx_module->new(
         context => $CTX,
         global => $CTX->{global},
         log => $CTX->{log},
      );
      #$__ctx_new->init; # No init now. We wait first run() to let set() actions
      if (! defined($__ctx_new)) {
         $ERR = 1;
         my $MSG = "load: unable to create Brick [$__ctx_brick]";
         die("$MSG\n");
      }

      return $CTX->{loaded}->{$__ctx_brick} = $__ctx_new;
   }, brick => $brick);

   return $r;
}

sub available {
   my $self = shift;

   my $r = $self->call(sub {
      return $CTX->{available};
   });

   return $r;
}

sub is_available {
   my $self = shift;
   my ($brick) = @_;

   if (! defined($brick)) {
      return $self->log->info($self->help_run('is_available'));
   }

   my $available = $self->available;
   if (exists($available->{$brick})) {
      return 1;
   }

   return 0;
}

sub loaded {
   my $self = shift;

   my $r = $self->call(sub {
      return $CTX->{loaded};
   });

   return $r;
}

sub is_loaded {
   my $self = shift;
   my ($brick) = @_;

   if (! defined($brick)) {
      return $self->log->info($self->help_run('is_loaded'));
   }

   my $loaded = $self->loaded;
   if (exists($loaded->{$brick})) {
      return 1;
   }

   return 0;
}

sub status {
   my $self = shift;

   my $available = $self->available;
   my $loaded = $self->loaded;

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

      my $__ctx_brick = $args{brick};
      my $__ctx_attribute = $args{attribute};
      my $__ctx_value = $args{value};

      my $ERR = 0;

      if (! $CTX->is_loaded($__ctx_brick)) {
         $ERR = 1;
         my $MSG = "set: Brick [$__ctx_brick] not loaded";
         die("$MSG\n");
      }

      if (! $CTX->loaded->{$__ctx_brick}->has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "set: Brick [$__ctx_brick] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      if ($__ctx_value =~ /^(\$.*)$/) {
         $__ctx_value = eval("\$CTX->_lp->{context}->{_}->{'$1'}");
      }

      $CTX->{loaded}->{$__ctx_brick}->$__ctx_attribute($__ctx_value);

      my $SET = $CTX->{set}->{$__ctx_brick}->{$__ctx_attribute} = $__ctx_value;

      my $RES = \$SET;

      return $SET;
   }, brick => $brick, attribute => $attribute, value => $value);

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

      my $__ctx_brick = $args{brick};
      my $__ctx_attribute = $args{attribute};

      my $ERR = 0;

      if (! $CTX->is_loaded($__ctx_brick)) {
         $ERR = 1;
         my $MSG = "set: Brick [$__ctx_brick] not loaded";
         die("$MSG\n");
      }

      if (! $CTX->loaded->{$__ctx_brick}->has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "set: Brick [$__ctx_brick] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      if (! defined($CTX->{loaded}->{$__ctx_brick}->$__ctx_attribute)) {
         return my $GET = 'undef';
      }

      my $GET = $CTX->{loaded}->{$__ctx_brick}->$__ctx_attribute;

      my $RES = \$GET;

      return $GET;
   }, brick => $brick, attribute => $attribute);

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

      my $__ctx_brick = $args{brick};
      my $__ctx_command = $args{command};
      my @__ctx_args = @{$args{args}};

      my $ERR = 0;

      if (! $CTX->is_loaded($__ctx_brick)) {
         $ERR = 1;
         my $MSG = "run: Brick [$__ctx_brick] not loaded";
         die("$MSG\n");
      }

      if (! $CTX->loaded->{$__ctx_brick}->has_command($__ctx_command)) {
         $ERR = 1;
         my $MSG = "run: Brick [$__ctx_brick] has no Command [$__ctx_command]";
         die("$MSG\n");
      }

      my $__ctx_run = $CTX->{loaded}->{$__ctx_brick};

      $__ctx_run->init; # Will init() only if not already done

      for (@__ctx_args) {
         if (/^(\$.*)$/) {
            $_ = eval("\$CTX->_lp->{context}->{_}->{'$1'}");
         }
      }

      my $RUN = $__ctx_run->$__ctx_command(@__ctx_args);
      if (! defined($RUN)) {
         $ERR = 1;
      }

      my $RES = \$RUN;

      return $RUN;
   }, brick => $brick, command => $command, args => \@args);

   return $r;
}

1;

__END__
