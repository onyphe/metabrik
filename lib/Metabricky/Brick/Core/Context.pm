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
my $__CTX;

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
            return $__CTX->{log};
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
         '$__CTX' => { },
         '$CONTEXT' => $self,
         '$SET' => 'undef',
         '$GET' => 'undef',
         '$RUN' => 'undef',
         '$ERR' => 'undef',
         '$MSG' => 'undef',
      });
      $lp->call(sub {
         my %args = @_;

         eval("use strict;");
         eval("use warnings;");

         $__CTX->{context} = $args{self};

         $__CTX->{loaded} = {
            'core::context' => $__CTX->{context},
            'core::global' => Metabricky::Brick::Core::Global->new->init,
            'core::log' => Metabricky::Brick::Core::Log->new->init,
         };
         $__CTX->{available} = { };
         $__CTX->{set} = { };
         $__CTX->{log} = $__CTX->{loaded}->{'core::log'};
         $__CTX->{global} = $__CTX->{loaded}->{'core::global'};

         # We don't use the log accessor to write the value because we wrote 
         # our own log accessor.
         $__CTX->{loaded}->{'core::context'}->{log} = $__CTX->{log};
         $__CTX->{loaded}->{'core::global'}->{log} = $__CTX->{log};

         # When new() was done, bricks was empty. We fix that here.
         $__CTX->{loaded}->{'core::global'}->{context} = $__CTX->{context};
         $__CTX->{loaded}->{'core::log'}->{context} = $__CTX->{context};

         # We did put log and context in Attributes, why not also put global:
         $__CTX->{loaded}->{'core::context'}->{global} = $__CTX->{global};
         $__CTX->{loaded}->{'core::log'}->{global} = $__CTX->{global};

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

      my $__lp_varname = $args{varname};

      return $__CTX->{context}->_lp->{context}->{_}->{$__lp_varname};
   }, varname => $varname);

   $self->debug && $self->log->debug("lookup: [$varname] = [".substr($res, 0, 128)."..]");

   return $res;
}

sub variables {
   my $self = shift;

   my $res = $self->call(sub {
      my @__lp_variables = ();

      for my $__lp_variable (keys %{$__CTX->{context}->_lp->{context}->{_}}) {
         next if $__lp_variable !~ /^\$/;
         next if $__lp_variable =~ /^\$_/;

         push @__lp_variables, $__lp_variable;
      }

      return \@__lp_variables;
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

      return $__CTX->{available} = $args{available};
   }, available => $h);

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

   $self->debug && $self->log->debug("repository[$repository]");
   $self->debug && $self->log->debug("category[$category]");
   $self->debug && $self->log->debug("module[$module]");

   $repository = ucfirst($repository);
   $category = ucfirst($category);
   $module = ucfirst($module);

   $module = 'Metabricky::Brick::'.(length($repository) ? $repository.'::' : '').$category.'::'.$module;

   $self->debug && $self->log->debug("module2[$module]");

   if ($self->is_loaded($brick)) {
      return $self->log->error("load: Brick [$brick] already loaded");
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_module = $args{module};
      my $__lp_brick = $args{brick};

      my $ERR = 0;

      eval("use $__lp_module;");
      if ($@) {
         chomp($@);
         $ERR = 1;
         my $MSG = "load: unable to use module [$__lp_module]: $@";
         die("$MSG\n");
      }

      my $__lp_new = $__lp_module->new(
         context => $__CTX->{context},
         global => $__CTX->{global},
         log => $__CTX->{log},
      );
      #$__lp_new->init; # No init now. We wait first run() to let set() actions
      if (! defined($__lp_new)) {
         $ERR = 1;
         my $MSG = "load: unable to create Brick [$__lp_brick]";
         die("$MSG\n");
      }

      return $__CTX->{loaded}->{$__lp_brick} = $__lp_new;
   }, module => $module, brick => $brick);

   return $r;
}

sub available {
   my $self = shift;

   my $r = $self->call(sub {
      return $__CTX->{available};
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
      return $__CTX->{loaded};
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

   if (! $self->is_loaded($brick)) {
      return $self->log->error("set: Brick [$brick] not loaded");
   }

   if (! $self->loaded->{$brick}->has_attribute($attribute)) {
      return $self->log->error("set: Brick [$brick] has no Attribute [$attribute]");
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};
      my $__lp_value = $args{value};

      if ($__lp_value =~ /^(\$.*)$/) {
         $__lp_value = eval("\$__CTX->{context}->_lp->{context}->{_}->{'$1'}");
      }

      $__CTX->{loaded}->{$__lp_brick}->$__lp_attribute($__lp_value);

      return my $SET = $__CTX->{set}->{$__lp_brick}->{$__lp_attribute} = $__lp_value;
   }, brick => $brick, attribute => $attribute, value => $value);

   return $r;
}

sub get {
   my $self = shift;
   my ($brick, $attribute) = @_;

   if (! defined($brick) || ! defined($attribute)) {
      return $self->log->info($self->help_run('get'));
   }

   if (! $self->is_loaded($brick)) {
      return $self->log->error("set: Brick [$brick] not loaded");
   }

   if (! $self->loaded->{$brick}->has_attribute($attribute)) {
      return $self->log->error("set: Brick [$brick] has no Attribute [$attribute]");
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_attribute = $args{attribute};

      if (! defined($__CTX->{loaded}->{$__lp_brick}->$__lp_attribute)) {
         return my $GET = 'undef';
      }

      return my $GET = $__CTX->{loaded}->{$__lp_brick}->$__lp_attribute;
   }, brick => $brick, attribute => $attribute);

   return $r;
}

sub run {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   if (! defined($brick) || ! defined($command)) {
      return $self->log->info($self->help_run('run'));
   }

   if (! $self->is_loaded($brick)) {
      return $self->log->error("run: Brick [$brick] not loaded");
   }

   if (! $self->loaded->{$brick}->has_command($command)) {
      return $self->log->error("run: Brick [$brick] has no Command [$command]");
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_command = $args{command};
      my @__lp_args = @{$args{args}};

      my $__lp_run = $__CTX->{loaded}->{$__lp_brick};

      $__lp_run->init; # Will init() only if not already done

      for (@__lp_args) {
         if (/^(\$.*)$/) {
            $_ = eval("\$__CTX->{context}->_lp->{context}->{_}->{'$1'}");
         }
      }

      my $ERR = 0;
      my $RUN = $__lp_run->$__lp_command(@__lp_args);
      if (! defined($RUN)) {
         $ERR = 1;
      }

      return $RUN;
   }, brick => $brick, command => $command, args => \@args);

   return $r;
}

1;

__END__
