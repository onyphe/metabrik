#
# $Id$
#
package Metabrik::Core::Context;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(core context main) ],
      attributes => {
         _lp => [ qw(INTERNAL) ],
      },
      commands => {
         use => [ qw(Brik) ],
         set => [ qw(Brik Attribute Value) ],
         get => [ qw(Brik Attribute) ],
         run => [ qw(Brik Command) ],
         do => [ qw(Code) ],
         call => [ qw(Code) ],
         variables => [ ],
         find_available => [ ],
         update_available => [ ],
         available => [ ],
         is_available => [ qw(Brik) ],
         used => [ ],
         is_used => [ qw(Brik) ],
         not_used => [ ],
         is_not_used => [ qw(Brik) ],
         status => [ ],
         reuse => [ ],
      },
      require_modules => {
         'Lexical::Persistence' => [ ],
         'File::Find' => [ ],
         'Module::Reload' => [ ],
         'Metabrik::Core::Global' => [ ],
         'Metabrik::Core::Log' => [ ],
         'Metabrik::Core::Shell' => [ ],
      },
   };
}

# Only used to avoid compile-time errors
my $CON;
my $SHE;
my $LOG;
my $GLO;

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
            return $CON->{log};
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

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   eval {
      my $lp = Lexical::Persistence->new;
      $lp->set_context(_ => {
         '$CON' => 'undef',
         '$SHE' => 'undef',
         '$LOG' => 'undef',
         '$GLO' => 'undef',
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

         $CON = $args{self};

         $CON->{used} = {
            'core::context' => $CON,
            'core::global' => Metabrik::Core::Global->new,
            'core::log' => Metabrik::Core::Log->new,
            'core::shell' => Metabrik::Core::Shell->new,
         };
         $CON->{available} = { };
         $CON->{set} = { };

         $CON->{log} = $CON->{used}->{'core::log'};
         $CON->{global} = $CON->{used}->{'core::global'};
         $CON->{shell} = $CON->{used}->{'core::shell'};
         $CON->{context} = $CON->{used}->{'core::context'};

         $SHE = $CON->{shell};
         $LOG = $CON->{log};
         $GLO = $CON->{global};

         # When new() was done, some Attributes were empty. We fix that here.
         $CON->{used}->{'core::context'}->{log} = $CON->{log};
         $CON->{used}->{'core::global'}->{log} = $CON->{log};
         $CON->{used}->{'core::shell'}->{log} = $CON->{log};
         $CON->{used}->{'core::log'}->{log} = $CON->{log};

         # When new() was done, some Attributes were empty. We fix that here.
         $CON->{used}->{'core::global'}->{context} = $CON;
         $CON->{used}->{'core::log'}->{context} = $CON;
         $CON->{used}->{'core::shell'}->{context} = $CON;
         $CON->{used}->{'core::context'}->{context} = $CON;

         # When new() was done, some Attributes were empty. We fix that here.
         $CON->{used}->{'core::context'}->{global} = $CON->{global};
         $CON->{used}->{'core::log'}->{global} = $CON->{global};
         $CON->{used}->{'core::shell'}->{global} = $CON->{global};
         $CON->{used}->{'core::global'}->{global} = $CON->{global};

         # When new() was done, some Attributes were empty. We fix that here.
         $CON->{used}->{'core::global'}->{shell} = $CON->{shell};
         $CON->{used}->{'core::context'}->{shell} = $CON->{shell};
         $CON->{used}->{'core::log'}->{shell} = $CON->{shell};
         $CON->{used}->{'core::shell'}->{shell} = $CON->{shell};

         my $ERR = 0;

         return 1;
      }, self => $self);
      $self->_lp($lp);
   };
   if ($@) {
      chomp($@);
      die("[F] core::context: new: unable to create context: $@\n");
   }

   return $self->brik_preinit;
}

sub brik_init {
   my $self = shift->SUPER::brik_init(
      @_,
   ) or return 1; # Init already done

   my $on_int = sub {
       $self->debug && $self->log->debug("INT captured");
       return 1;
   };

   $SIG{INT} = $on_int;
   $SIG{TERM} = $on_int;

   my $r = $self->update_available;
   if (! defined($r)) {
      return $self->log->error("brik_init: unable to init Brik [core::context]: ".
         "update_available failed"
      );
   }

   return $self;
}

sub do {
   my $self = shift;
   my ($code) = @_;

   if (! defined($code)) {
      return $self->log->error($self->brik_help_run('do'));
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
      return $self->log->error($self->brik_help_run('call'));
   }

   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->call($subref, %args);
   };
   if ($@) {
      chomp($@);
      my @list = caller();
      my $file = $list[1];
      my $line = $list[2];
      return $self->log->error("call: $@ (source file [$file] at line [$line])");
   }

   return $res;
}

sub variables {
   my $self = shift;

   my $res = $self->call(sub {
      my @__ctx_variables = ();

      for my $__ctx_variable (keys %{$CON->_lp->{context}->{_}}) {
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

   # Read from @INC, exclude current directory
   my @path_list = ();
   for (@INC) {
      next if /^\.$/;
      push @path_list, $_;
   }

   my $dirpattern = 'Metabrik/';
   my $filepattern = '.pm$';

   # Extracted from file::find Brik

   # Escape if we are searching for a directory hierarchy
   $dirpattern =~ s/\//\\\//g;

   my $dir_regex = qr/$dirpattern/;
   my $file_regex = qr/$filepattern/;
   my $dot_regex = qr/^\.$/;
   my $dot2_regex = qr/^\.\.$/;

   my @files = ();

   my $sub = sub {
      my $dir = $File::Find::dir;
      my $file = $_;
      # Skip dot and double dot directories
      if ($file =~ $dot_regex || $file =~ $dot2_regex) {
      }
      elsif ($dir =~ $dir_regex && $file =~ $file_regex) {
         push @files, "$dir/$file";
      }
   };

   {
      no warnings;
      File::Find::find($sub, @path_list);
   };

   my %uniq_files = map { $_ => 1 } @files;
   @files = sort { $a cmp $b } keys %uniq_files;

   # /extract

   my %available = ();
   for my $this (@files) {
      my $brik = $this;
      $brik =~ s/\//::/g;
      $brik =~ s/^.*::Metabrik::(.*?)$/$1/;
      $brik =~ s/.pm$//;
      if (length($brik)) {
         my $module = "Metabrik::$brik";
         $brik = lc($brik);
         $available{$brik} = $module;
      }
   }

   return \%available;
}

sub update_available {
   my $self = shift;

   my $h = $self->find_available;

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_available = $args{available};

      for my $__ctx_this (keys %$__ctx_available) {
         eval("require ".$__ctx_available->{$__ctx_this});
      }

      return $CON->{available} = $args{available};
   }, available => $h);

   return $r;
}

sub use {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('use'));
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

      if ($CON->debug) {
         $CON->log->debug("repository[$__ctx_brik_repository]");
         $CON->log->debug("category[$__ctx_brik_category]");
         $CON->log->debug("module[$__ctx_brik_module]");
      }

      $__ctx_brik_repository = ucfirst($__ctx_brik_repository);
      $__ctx_brik_category = ucfirst($__ctx_brik_category);
      $__ctx_brik_module = ucfirst($__ctx_brik_module);

      my $__ctx_module = 'Metabrik::'.(length($__ctx_brik_repository)
         ? $__ctx_brik_repository.'::'
         : '').$__ctx_brik_category.'::'.$__ctx_brik_module;

      $CON->debug && $CON->log->debug("module2[$__ctx_brik_module]");

      if ($CON->is_used($__ctx_brik)) {
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
         context => $CON,
         global => $CON->{global},
         shell => $CON->{shell},
         log => $CON->{log},
      );
      #$__ctx_new->brik_init; # No init now. We wait first run() to let set() actions
      if (! defined($__ctx_new)) {
         $ERR = 1;
         my $MSG = "use: unable to use Brik [$__ctx_brik]";
         die("$MSG\n");
      }

      $USE = $__ctx_brik;

      return $CON->{used}->{$__ctx_brik} = $__ctx_new;
   }, brik => $brik);

   return $r;
}

sub reuse {
   my $self = shift;

   my $reused = Module::Reload->check;
   if ($reused) {
      $self->log->info("reuse: some modules were reused");
   }

   return 1;
}

sub available {
   my $self = shift;

   my $r = $self->call(sub {
      return $CON->{available};
   });

   return $r;
}

sub is_available {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('is_available'));
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
      return $CON->{used};
   });

   return $r;
}

sub is_used {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('is_used'));
   }

   my $used = $self->used;
   if (exists($used->{$brik})) {
      return 1;
   }

   return 0;
}

sub not_used {
   my $self = shift;

   my $status = $self->status;

   my $r = {};
   my @not_used = @{$status->{not_used}};
   for my $this (@not_used) {
      my @toks = split('::', $this);

      my $repository = '';
      my $category = '';
      my $name = '';

      # No repository defined
      if (@toks == 2) {
         ($category, $name) = $this =~ /^(.*?)::(.*)/;
      }
      elsif (@toks > 2) {
         ($repository, $category, $name) = $this =~ /^(.*?)::(.*?)::(.*)/;
      }

      my $class = 'Metabrik::';
      if (length($repository)) {
         $class .= ucfirst($repository).'::';
      }
      $class .= ucfirst($category).'::';
      $class .= ucfirst($name);

      $r->{$this} = $class;
   }

   return $r;
}

sub is_not_used {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('is_not_used'));
   }

   my $used = $self->not_used;
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
      return $self->log->error($self->brik_help_run('set'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_attribute = $args{attribute};
      my $__ctx_value = $args{value};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "set: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CON->used->{$__ctx_brik}->brik_has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "set: Brik [$__ctx_brik] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      if ($__ctx_value =~ /^(\$.*)$/) {
         $__ctx_value = eval("\$CON->_lp->{context}->{_}->{'$1'}");
      }

      $CON->{used}->{$__ctx_brik}->$__ctx_attribute($__ctx_value);

      my $SET = $CON->{set}->{$__ctx_brik}->{$__ctx_attribute} = $__ctx_value;

      my $REF = \$SET;

      return $SET;
   }, brik => $brik, attribute => $attribute, value => $value);

   return $r;
}

sub get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   if (! defined($brik) || ! defined($attribute)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_attribute = $args{attribute};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "get: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CON->used->{$__ctx_brik}->brik_has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "get: Brik [$__ctx_brik] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      if (! defined($CON->{used}->{$__ctx_brik}->$__ctx_attribute)) {
         return my $GET = 'undef';
      }

      my $GET = $CON->{used}->{$__ctx_brik}->$__ctx_attribute;

      my $REF = \$GET;

      return $GET;
   }, brik => $brik, attribute => $attribute);

   return $r;
}

sub run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   if (! defined($brik) || ! defined($command)) {
      return $self->log->error($self->brik_help_run('run'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_command = $args{command};
      my @__ctx_args = @{$args{args}};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "run: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CON->used->{$__ctx_brik}->brik_has_command($__ctx_command)) {
         $ERR = 1;
         my $MSG = "run: Brik [$__ctx_brik] has no Command [$__ctx_command]";
         die("$MSG\n");
      }

      my $__ctx_run = $CON->{used}->{$__ctx_brik};

      $__ctx_run->brik_init; # Will brik_init() only if not already done

      for (@__ctx_args) {
         if (/^(\$.*)$/) {
            $_ = eval("\$CON->_lp->{context}->{_}->{'$1'}");
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
