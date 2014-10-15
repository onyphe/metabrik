#
# $Id$
#
package Metabrik::Brik::Core::Context;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(core context main) ],
      attributes => {
         _lp => [ qw(OBJECT) ],
      },
      commands => {
         use => [ qw(SCALAR) ],
         set => [ qw(SCALAR SCALAR SCALAR) ],
         get => [ qw(SCALAR SCALAR) ],
         run => [ qw(SCALAR SCALAR) ],
         do => [ qw(SCALAR) ],
         call => [ qw(SCALAR) ],
         variables => [ ],
         find_available => [ ],
         update_available => [ ],
         available => [ ],
         is_available => [ qw(SCALAR) ],
         used => [ ],
         is_used => [ qw(SCALAR) ],
         status => [ ],
      },
      require_modules => {
         'CPAN::Lexical::Persistence' => [],
         'Metabrik::Brik::Core::Global' => [],
         'Metabrik::Brik::Core::Log' => [],
         'Metabrik::Brik::Core::Shell' => [],
         'Metabrik::Brik::File::Find' => [],
      },
   };
}

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
         die("[F] core::context: log: $@\n");
      }

      $@ = $save;

      return $r;
   };
}

sub help {
   return {
      'run:use' => '<brik>',
      'run:set' => '<brik> <attribute> <value>',
      'run:get' => '<brik> <attribute>',
      'run:run' => '<brik> <command> [ <arg1 arg2 .. argN> ]',
      'run:used' => '',
      'run:is_used' => '<brik>',
      'run:find_available' => '',
      'run:update_available' => '',
      'run:available' => '',
      'run:is_available' => '<brik>',
      'run:status' => '',
      'run:variables' => '',
   };
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   eval {
      my $lp = CPAN::Lexical::Persistence->new;
      $lp->set_context(_ => {
         '$CTX' => 'undef',
         '$USE' => 'undef',
         '$SET' => 'undef',
         '$GET' => 'undef',
         '$RUN' => 'undef',
         '$ERR' => 'undef',
         '$MSG' => 'undef',
         '$REF' => 'undef',
      });
      $lp->call(sub {
         my %args = @_;

         $CTX = $args{self};

         $CTX->{used} = {
            'core::context' => $CTX,
            'core::global' => Metabrik::Brik::Core::Global->new,
            'core::log' => Metabrik::Brik::Core::Log->new,
            'core::shell' => Metabrik::Brik::Core::Shell->new,
         };
         $CTX->{available} = { };
         $CTX->{set} = { };

         $CTX->{log} = $CTX->{used}->{'core::log'};
         $CTX->{global} = $CTX->{used}->{'core::global'};
         $CTX->{shell} = $CTX->{used}->{'core::shell'};
         $CTX->{context} = $CTX->{used}->{'core::context'};

         # When new() was done, some Attributes were empty. We fix that here.
         $CTX->{used}->{'core::context'}->{log} = $CTX->{log};
         $CTX->{used}->{'core::global'}->{log} = $CTX->{log};
         $CTX->{used}->{'core::shell'}->{log} = $CTX->{log};
         $CTX->{used}->{'core::log'}->{log} = $CTX->{log};

         # When new() was done, some Attributes were empty. We fix that here.
         $CTX->{used}->{'core::global'}->{context} = $CTX;
         $CTX->{used}->{'core::log'}->{context} = $CTX;
         $CTX->{used}->{'core::shell'}->{context} = $CTX;
         $CTX->{used}->{'core::context'}->{context} = $CTX;

         # When new() was done, some Attributes were empty. We fix that here.
         $CTX->{used}->{'core::context'}->{global} = $CTX->{global};
         $CTX->{used}->{'core::log'}->{global} = $CTX->{global};
         $CTX->{used}->{'core::shell'}->{global} = $CTX->{global};
         $CTX->{used}->{'core::global'}->{global} = $CTX->{global};

         # When new() was done, some Attributes were empty. We fix that here.
         $CTX->{used}->{'core::global'}->{shell} = $CTX->{shell};
         $CTX->{used}->{'core::context'}->{shell} = $CTX->{shell};
         $CTX->{used}->{'core::log'}->{shell} = $CTX->{shell};
         $CTX->{used}->{'core::shell'}->{shell} = $CTX->{shell};

         my $ERR = 0;

         return 1;
      }, self => $self);
      $self->_lp($lp);
   };
   if ($@) {
      chomp($@);
      die("[F] core::context: new: unable to create context: $@\n");
   }

   return $self->preinit;
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $r = $self->update_available;
   if (! defined($r)) {
      return $self->log->error("init: unable to init Brik [core::context]: ".
         "update_available failed"
      );
   }

   return $self;
}

sub do {
   my $self = shift;
   my ($code) = @_;

   if (! defined($code)) {
      return $self->log->info($self->help_run('do'));
   }

   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->do($code);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("do: $@");
   }

   $self->debug && $self->log->debug("do: returned[".(defined($res) ? $res : 'undef')."]");

   return defined($res) ? $res : 'undef';
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

sub find_available {
   my $self = shift;

   my $file_find = Metabrik::Brik::File::Find->new(
      context => $self,
      global => $self->global,
      log => $self->log,
   ) or return;

   # Read from @INC, exclude current directory
   my @new = ();
   for (@INC) {
      next if /^\.$/;
      push @new, $_;
   }

   $file_find->path(join(':', @new));
   $file_find->recursive(1);
   $file_find->debug(1);

   my $found = $file_find->all('Metabrik/Brik/', '.pm$') or return;

   my @available = ();
   for my $this (@{$found->{files}}) {
      my $brik = lc($this);
      $brik =~ s/\//::/g;
      $brik =~ s/^.*::metabrik::brik::(.*?)$/$1/;
      $brik =~ s/.pm$//;
      if (length($brik)) {
         push @available, $brik;
      }
   }

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

sub use {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->info($self->help_run('use'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};

      my $ERR = 0;
      my $USE = 'undef';

      my $__ctx_brik_repository = '';
      my $__ctx_brik_category = '';
      my $__ctx_brik_module = '';

      if ($__ctx_brik =~ /^[a-z0-9]+::[a-z0-9]+$/) {
         ($__ctx_brik_category, $__ctx_brik_module) = split('::', $__ctx_brik);
      }
      elsif ($__ctx_brik =~ /^[a-z0-9]+::[a-z0-9]+::[a-z0-9]+$/) {
         ($__ctx_brik_repository, $__ctx_brik_category, $__ctx_brik_module) = split('::', $__ctx_brik);
      }
      else {
         $ERR = 1;
         my $MSG = "use: invalid format for Brik [$__ctx_brik]";
         die("$MSG\n");
      }

      if ($CTX->debug) {
         $CTX->log->debug("repository[$__ctx_brik_repository]");
         $CTX->log->debug("category[$__ctx_brik_category]");
         $CTX->log->debug("module[$__ctx_brik_module]");
      }

      $__ctx_brik_repository = ucfirst($__ctx_brik_repository);
      $__ctx_brik_category = ucfirst($__ctx_brik_category);
      $__ctx_brik_module = ucfirst($__ctx_brik_module);

      my $__ctx_module = 'Metabrik::Brik::'.(length($__ctx_brik_repository)
         ? $__ctx_brik_repository.'::'
         : '').$__ctx_brik_category.'::'.$__ctx_brik_module;

      $CTX->debug && $CTX->log->debug("module2[$__ctx_brik_module]");

      if ($CTX->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "use: Brik [$__ctx_brik] already used";
         die("$MSG\n");
      }

      eval("require $__ctx_module;");
      if ($@) {
         chomp($@);
         $ERR = 1;
         my $MSG = "use: unable to use Brik [$__ctx_brik]: $@";
         die("$MSG\n");
      }

      my $__ctx_new = $__ctx_module->new(
         context => $CTX,
         global => $CTX->{global},
         shell => $CTX->{shell},
         log => $CTX->{log},
      );
      #$__ctx_new->init; # No init now. We wait first run() to let set() actions
      if (! defined($__ctx_new)) {
         $ERR = 1;
         my $MSG = "use: unable to use Brik [$__ctx_brik]";
         die("$MSG\n");
      }

      $USE = $__ctx_brik;

      return $CTX->{used}->{$__ctx_brik} = $__ctx_new;
   }, brik => $brik);

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
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->info($self->help_run('is_available'));
   }

   my $available = $self->available;
   if (exists($available->{$brik})) {
      return 1;
   }

   return 0;
}

sub used {
   my $self = shift;

   my $r = $self->call(sub {
      return $CTX->{used};
   });

   return $r;
}

sub is_used {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->info($self->help_run('is_used'));
   }

   my $used = $self->used;
   if (exists($used->{$brik})) {
      return 1;
   }

   return 0;
}

sub status {
   my $self = shift;

   my $available = $self->available;
   my $used = $self->used;

   my @used = ();
   my @not_used = ();

   for my $k (sort { $a cmp $b } keys %$available) {
      exists($used->{$k}) ? push @used, $k : push @not_used, $k;
   }

   return {
      used => \@used,
      not_used => \@not_used,
   };
}

sub set {
   my $self = shift;
   my ($brik, $attribute, $value) = @_;

   if (! defined($brik) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info($self->help_run('set'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_attribute = $args{attribute};
      my $__ctx_value = $args{value};

      my $ERR = 0;

      if (! $CTX->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "set: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CTX->used->{$__ctx_brik}->has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "set: Brik [$__ctx_brik] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      if ($__ctx_value =~ /^(\$.*)$/) {
         $__ctx_value = eval("\$CTX->_lp->{context}->{_}->{'$1'}");
      }

      $CTX->{used}->{$__ctx_brik}->$__ctx_attribute($__ctx_value);

      my $SET = $CTX->{set}->{$__ctx_brik}->{$__ctx_attribute} = $__ctx_value;

      my $REF = \$SET;

      return $SET;
   }, brik => $brik, attribute => $attribute, value => $value);

   return $r;
}

sub get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   if (! defined($brik) || ! defined($attribute)) {
      return $self->log->info($self->help_run('get'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_attribute = $args{attribute};

      my $ERR = 0;

      if (! $CTX->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "get: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CTX->used->{$__ctx_brik}->has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "get: Brik [$__ctx_brik] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      if (! defined($CTX->{used}->{$__ctx_brik}->$__ctx_attribute)) {
         return my $GET = 'undef';
      }

      my $GET = $CTX->{used}->{$__ctx_brik}->$__ctx_attribute;

      my $REF = \$GET;

      return $GET;
   }, brik => $brik, attribute => $attribute);

   return $r;
}

sub run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   if (! defined($brik) || ! defined($command)) {
      return $self->log->info($self->help_run('run'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_command = $args{command};
      my @__ctx_args = @{$args{args}};

      my $ERR = 0;

      if (! $CTX->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "run: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CTX->used->{$__ctx_brik}->has_command($__ctx_command)) {
         $ERR = 1;
         my $MSG = "run: Brik [$__ctx_brik] has no Command [$__ctx_command]";
         die("$MSG\n");
      }

      my $__ctx_run = $CTX->{used}->{$__ctx_brik};

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

      my $REF = \$RUN;

      return $RUN;
   }, brik => $brik, command => $command, args => \@args);

   return $r;
}

1;

__END__
