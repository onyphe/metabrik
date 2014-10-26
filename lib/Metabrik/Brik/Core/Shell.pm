#
# $Id$
#
# core::shell Brik
#
package Metabrik::Brik::Core::Shell;
use strict;
use warnings;

use base qw(CPAN::Term::Shell Metabrik::Brik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(used core main shell) ],
      attributes => {
         echo => [ qw(SCALAR) ],
         pager_threshold => [ qw(SCALAR) ],
         help_show_brik_commands => [ qw(SCALAR) ],
         help_show_brik_attributes => [ qw(SCALAR) ],
         comp_show_brik_attributes => [ qw(SCALAR) ],
         comp_show_brik_commands => [ qw(SCALAR) ],
         get_show_brik_attributes => [ qw(SCALAR) ],
         # These are used by Term::Shell
         #path_home => [ qw(SCALAR) ],
         #path_cwd => [ qw(SCALAR) ],
         #prompt => [ qw(SCALAR) ],
         #_aliases => [ qw(SCALAR) ],
      },
      attributes_default => {
         echo => 1,
         pager_threshold => 1024,
         help_show_brik_commands => 0,
         help_show_brik_attributes => 0,
         comp_show_brik_attributes => 0,
         comp_show_brik_commands => 0,
         get_show_brik_attributes => 0,
      },
      commands => {
         splash => [ ],
         run_cd => [ qw(SCALAR) ],
         run_use => [ qw(SCALAR) ],
         run_set => [ qw(SCALAR SCALAR SCALAR) ],
         run_get => [ qw(SCALAR SCALAR) ],
         run_run => [ qw(SCALAR SCALAR) ],
         run_perl => [ qw(SCALAR) ],
         run_exit => [ ],
         cmd => [ qw(SCALAR) ],
         cmdloop => [ ],
      },
      require_modules => {
         'CPAN::Data::Dump' => [ 'dump' ],
      },
   };
}

sub new {
   # Call Term::Shell new()
   my $self = shift->SUPER::new(@_);

   # Call Metabrik::Brik new()
   $self->Metabrik::Brik::new(@_);

   # We have to set of default_attributes again normally called by Brik::new():
   # Otherwise default attributes are not set properly because of Perl inheritance scheme
   $self->brik_set_default_attributes;

   # Now write Term::Shell default values we gave, like context, global, log, ...
   my %h = @_;
   for my $k (keys %h) {
      $self->{$k} = $h{$k};
   }

   return $self;
}

sub brik_init {
   my $self = shift->SUPER::brik_init(
      @_,
   ) or return 1; # Init already done

   my $context = $self->context;

   $self->debug && $self->log->debug("brik_init: start");

   if ($context->is_used('shell::rc')) {
      $self->debug && $self->log->debug("brik_init: load rc file");

      my $cmd = $context->run('shell::rc', 'load');
      for (@$cmd) {
         $self->cmd($_);
      }
   }

   $self->debug && $self->log->debug("brik_init: done");

   return $self;
}

sub splash {
   my $self = shift;

   my $version = $self->context->run('core::global', 'brik_version');

   # ASCII art courtesy: http://patorjk.com/software/taag/#p=testall&f=Graffiti&t=MetabriK
   print<<EOF

        ███▄ ▄███▓▓█████▄▄▄█████▓ ▄▄▄       ▄▄▄▄    ██▀███   ██▓ ██ ▄█▀
       ▓██▒▀█▀ ██▒▓█   ▀▓  ██▒ ▓▒▒████▄    ▓█████▄ ▓██ ▒ ██▒▓██▒ ██▄█▒
       ▓██    ▓██░▒███  ▒ ▓██░ ▒░▒██  ▀█▄  ▒██▒ ▄██▓██ ░▄█ ▒▒██▒▓███▄░
       ▒██    ▒██ ▒▓█  ▄░ ▓██▓ ░ ░██▄▄▄▄██ ▒██░█▀  ▒██▀▀█▄  ░██░▓██ █▄
       ▒██▒   ░██▒░▒████▒ ▒██▒ ░  ▓█   ▓██▒░▓█  ▀█▓░██▓ ▒██▒░██░▒██▒ █▄
       ░ ▒░   ░  ░░░ ▒░ ░ ▒ ░░    ▒▒   ▓▒█░░▒▓███▀▒░ ▒▓ ░▒▓░░▓  ▒ ▒▒ ▓▒
       ░  ░      ░ ░ ░  ░   ░      ▒   ▒▒ ░▒░▒   ░   ░▒ ░ ▒░ ▒ ░░ ░▒ ▒░
       ░      ░      ░    ░        ░   ▒    ░    ░   ░░   ░  ▒ ░░ ░░ ░
              ░      ░  ░              ░  ░ ░         ░      ░  ░  ░
                                                 ░

--[ Welcome to Metabrik - Knowledge is in your head, Detail is in the code ]--
--[ Version $version ]--

    There is a Brik for that.

EOF
;

   return 1;
}

#
# Term::Shell stuff
#
use Cwd;
use File::HomeDir qw(home);

use Metabrik;
use Metabrik::Brik::File::Find;

our $AUTOLOAD;

sub AUTOLOAD {
   my $self = shift;
   my (@args) = @_;

   if ($AUTOLOAD !~ /^Metabrik::Brik::Core::Shell::run_/) {
      return 1;
   }

   (my $alias = $AUTOLOAD) =~ s/^Metabrik::Brik::Core::Shell:://;

   if ($self->debug) {
      $self->log->debug("autoload[$AUTOLOAD]");
      $self->log->debug("alias[$alias]");
      $self->log->debug("args[@args]");
   }

   #my $aliases = $self->_aliases;
   my $aliases = $self->{_aliases};
   if (exists($aliases->{$alias})) {
      my $cmd = $aliases->{$alias};
      return $self->cmd(join(' ', $cmd, @args));
   }

   return 1;
}

# Converts Windows path
sub _convert_path {
   my ($path) = @_;

   $path =~ s/\\/\//g;

   return $path;
}

#
# Term::Shell::main stuff
#
sub _update_path_home {
   my $self = shift;

   #$self->path_home(_convert_path(home()));
   $self->{path_home} = _convert_path(home());

   return 1;
}

sub _update_path_cwd {
   my $self = shift;

   my $cwd = _convert_path(getcwd());
   #my $home = $self->path_home;
   my $home = $self->{path_home};
   $cwd =~ s/^$home/~/;

   #$self->path_cwd($cwd);
   $self->{path_cwd} = $cwd;

   return 1;
}

sub _update_prompt {
   my $self = shift;
   my ($prompt) = @_;

   if (defined($prompt)) {
      #$self->prompt($prompt);
      $self->{prompt} = $prompt;
   }
   else {
      #my $cwd = $self->path_cwd;
      my $cwd = $self->{path_cwd};

      my $prompt = "Meta:$cwd> ";
      #my $prompt = "Meta> ";
      if ($^O =~ /win32/i) {
         $prompt =~ s/> /\$ /;
      }
      elsif ($< == 0) {
         $prompt =~ s/> /# /;
      }

      #$self->prompt($prompt);
      $self->{prompt} = $prompt;
   }

   return 1;
}

sub init {
   my $self = shift;

   $|++;

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("signal: INT caught");
      $self->run_exit;
      return 1;
   };

   $self->_update_path_home;
   $self->_update_path_cwd;
   $self->_update_prompt;

   # Default: 'us,ue,md,me', see `man 5 termcap' and Term::Cap
   # See also Term::ReadLine LoadTermCap() and ornaments() subs.
   $self->term->ornaments('md,me');

   # They are used when core::context init is performed
   # Should be placed in core::context Brik instead of here
   # No: has to be done when core::shell Brik is inited only.
   $self->add_handler('run_core::log');
   $self->add_handler('run_core::context');
   $self->add_handler('run_core::global');
   $self->add_handler('run_core::shell');

   return $self;
}

sub prompt_str {
   my $self = shift;

   #return $self->prompt;
   return $self->{prompt};
}

sub cmdloop {
   my $self = shift;

   $self->{stop} = 0;
   $self->preloop;

   my @lines = ();
   while (defined(my $line = $self->readline($self->prompt_str))) {
      push @lines, $line;

      if ($line =~ /\\\s*$/) {
         $self->_update_prompt('.. ');
         next;
      }

      # Multiline edition finished, we can remove the `\' char before joining
      for (@lines) {
         s/\\\s*$//;
      }

      $self->debug && $self->log->debug("cmdloop: lines[@lines]");

      $self->cmd(join('', @lines));
      @lines = ();
      $self->_update_prompt;

      last if $self->{stop};
   }

   $self->run_exit;

   return $self->postloop;
}

#
# Term::Shell::run stuff
#
sub run_exit {
   my $self = shift;

   my $context = $self->context;

   if ($context->is_used('shell::history')) {
      $context->run('shell::history', 'write');
   } 

   return $self->stoploop;
}

sub comp_exit {
   return ();
}

sub run_alias {
   my $self = shift;
   my ($alias, @cmd) = @_;

   #my $aliases = $self->_aliases;
   my $aliases = $self->{_aliases};

   if (! defined($alias)) {
      for my $this (keys %$aliases) {
         (my $alias = $this) =~ s/^run_//;
         $self->log->info(sprintf("%-10s \"%s\"", $alias, $aliases->{$this}));
      }

      return 1;
   }

   $aliases->{"run_$alias"} = join(' ', @cmd);
   #$self->_aliases($aliases);
   $self->{_aliases} = $aliases;

   $self->add_handler("run_$alias");

   return 1;
}

sub comp_alias {
   return ();
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   if (defined($dir)) {
      if ($dir =~ /^~$/) {
         #$dir = $self->path_home;
         $dir = $self->{path_home};
      }
      if (! -d $dir) {
         return $self->log->error("cd: $dir: can't cd to this");
      }
      chdir($dir);
      $self->_update_path_cwd;
   }
   else {
      #chdir($self->path_home);
      chdir($self->{path_home});
      $self->_update_path_cwd;
   }

   $self->_update_prompt;

   return 1;
}

sub comp_cd {
   my $self = shift;
   my ($word, $line, $start) = @_;

   return $self->catch_comp_sub($word, $start, $line);
}

sub run_perl {
   my $self = shift;

   my $context = $self->context;

   my $line = $self->line;
   $line =~ s/^pl\s+//;

   $self->debug && $self->log->debug("run_perl: code[$line]");

   my $r = $context->do($line);
   if (! defined($r)) {
      return $self->log->error("run_perl: unable to execute Code [$line]");
   }

   if ($self->echo) {
      if (length($r) < $self->pager_threshold) {
         print CPAN::Data::Dump::dump($r)."\n";
      }
      else {
         $self->page($r."\n");
      }
   }

   return $r;
}

sub comp_pl {
   my $self = shift;
   my ($word, $line, $start) = @_;

   return $self->catch_comp_sub($word, $start, $line);
}

sub run_use {
   my $self = shift;
   my ($brik, @args) = @_;

   my $context = $self->context;

   if (! defined($brik)) {
      return $self->log->info("use <brik>");
   }

   my $r;
   # If Brik starts with a minuscule, we want to use Brik in Metabrik sens.
   # Otherwise, it is a use command in the Perl sens.
   if ($brik =~ /^[a-z]/ && $brik =~ /::/) {
      $r = $context->use($brik) or return;
      if ($r) {
         $self->log->verbose("use: Brik [$brik] used");
      }

      $self->add_handler("run_$brik");
   }
   else {
      return $self->run_perl($brik, @args);
   }

   return $r;
}

sub comp_use {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find available briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      my $available = $context->available;
      if ($self->debug && ! defined($available)) {
         $self->log->debug("\ncomp_use: can't fetch available Briks");
         return ();
      }

      # Do not keep already used briks
      my $used = $context->used;
      for my $a (keys %$available) {
         next if $used->{$a};
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_help {
   my $self = shift;
   my ($brik) = @_;

   my $context = $self->context;

   if (! defined($brik)) {
      return $self->SUPER::run_help;
   }
   else {
      if ($context->is_used($brik)) {
         my $attributes = $context->run($brik, 'brik_attributes');
         my $commands = $context->run($brik, 'brik_commands');

         my $brik_attributes = Metabrik::Brik->brik_properties->{attributes};
         for my $attribute (keys %$attributes) {
            if (! $context->get('core::shell', 'help_show_brik_attributes')) {
               next if exists($brik_attributes->{$attribute});
            }
            my $help = $context->run($brik, 'brik_help_set', $attribute);
            $self->log->info($help) if defined($help);
         }

         my $brik_commands = Metabrik::Brik->brik_properties->{commands};
         for my $command (keys %$commands) {
            if (! $context->get('core::shell', 'help_show_brik_commands')) {
               next if exists($brik_commands->{$command});
            }
            my $help = $context->run($brik, 'brik_help_run', $command);
            $self->log->info($help) if defined($help);
         }
      }
      else {
         # We return to standard help() method
         return $self->SUPER::run_help($brik);
      }
   }

   return 1;
}

sub comp_help {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find help for used briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %{$self->{handlers}}) {
         next unless length($a);
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_set {
   my $self = shift;
   my ($brik, $attribute, $value) = @_;

   my $context = $self->context;

   if (! defined($brik) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info("set <brik> <attribute> <value>");
   }

   my $r = $context->set($brik, $attribute, $value);
   if (! defined($r)) {
      return $self->log->error("set: unable to set Attribute [$attribute] for Brik [$brik]");
   }

   return $r;
}

sub comp_set {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   # Completion is for used Briks only
   my $used = $context->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_set: can't fetch used Briks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Attributes
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_attributes = Metabrik::Brik->brik_properties->{attributes};
      my $attributes = $used->{$brik}->brik_attributes;
      for my $attribute (keys %$attributes) {
         if (! $context->get('core::shell', 'comp_show_brik_attributes')) {
            next if exists($brik_attributes->{$attribute});
         }
         push @comp, $attribute;
      }
   }
   # We want to complete entered Attribute
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $attributes = $used->{$brik}->brik_attributes;

      for my $a (keys %$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   else {
      return $self->catch_comp_sub($word, $start, $line);
   }

   return @comp;
}

sub run_get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   my $context = $self->context;

   # get is called without args, we display everything
   if (! defined($brik)) {
      my $used = $context->used or return;

      for my $brik (sort { $a cmp $b } keys %$used) {
         my $attributes = $used->{$brik}->brik_attributes or next;
         for my $attribute (sort { $a cmp $b } keys %$attributes) {
            if (! $context->get('core::shell', 'get_show_brik_attributes')) {
               if ($attribute =~ /^(?:shell|context|log|global|init_done|debug)$/) {
                  next;
               }
            }
            $self->log->info("$brik $attribute ".$context->get($brik, $attribute));
         }
      }
   }
   # get is called with only a Brik as an arg, we show its Attributes
   elsif (defined($brik) && ! defined($attribute)) {
      my $used = $context->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      my %printed = ();
      my $attributes = $used->{$brik}->brik_attributes;
      for my $attribute (sort { $a cmp $b } keys %$attributes) {
         if (! $context->get('core::shell', 'get_show_brik_attributes')) {
            if ($attribute =~ /^(?:shell|context|log|global|init_done|debug)$/) {
               next;
            }
         }
         my $print = "$brik $attribute ".$context->get($brik, $attribute);
         $self->log->info($print) if ! exists($printed{$print});
         $printed{$print}++;
      }
   }
   # get is called with is a Brik and an Attribute
   elsif (defined($brik) && defined($attribute)) {
      my $used = $context->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      if (! $used->{$brik}->brik_has_attribute($attribute)) {
         return $self->log->error("get: Attribute [$attribute] does not exist for Brik [$brik]");
      }

      $self->log->info("$brik $attribute ".$context->get($brik, $attribute));
   }

   return 1;
}

sub comp_get {
   my $self = shift;

   return $self->comp_set(@_);
}

sub run_run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   my $context = $self->context;

   if (! defined($brik) || ! defined($command)) {
      return $self->log->info("run <brik> <command> [ <arg1> <arg2> .. <argN> ]");
   }

   my $r = $context->run($brik, $command, @args);
   if (! defined($r)) {
      return $self->log->error("run: unable to execute Command [$command] for Brik [$brik]");
   }

   if ($self->echo) {
      if (length($r) < $self->pager_threshold) {
         print CPAN::Data::Dump::dump($r)."\n";
      }
      else {
         $self->page($r."\n");
      }
   }

   return $r;
}

sub comp_run {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("comp_run: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Completion is for used Briks only
   my $used = $context->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_run: can't fetch used Briks");
      return ();
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Commands
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_commands = Metabrik::Brik->brik_properties->{commands};
      my $commands = $used->{$brik}->brik_commands;
      for my $command (keys %$commands) {
         if (! $context->get('core::shell', 'comp_show_brik_commands')) {
            next if exists($brik_commands->{$command});
         }
         push @comp, $command;
      }
   }
   # We want to complete entered Command and Attributes
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $commands = $used->{$brik}->brik_commands;

      for my $a (keys %$commands) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   else {
      return $self->catch_comp_sub($word, $start, $line);
   }

   return @comp;
}

#
# Term::Shell::catch stuff
#
sub catch_run {
   my $self = shift;
   my (@args) = @_;

   # Default to execute Perl commands
   return $self->run_perl(@args);
}

# 1. $word - The word the user is trying to complete.
# 2. $line - The line as typed by the user so far.
# 3. $start - The offset into $line where $word starts.
sub catch_comp_sub {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("catch_comp: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Be default, we will read the current directory
   if (! length($word)) {
      $word = '.';
   }

   $self->debug && $self->log->debug("catch_comp: DEFAULT: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   my @comp = ();

   # We don't use $word here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $context->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         #$self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$word/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      #my $home = $self->path_home;
      my $home = $self->{path_home};
      $word =~ s/^~/$home/;

      if ($word =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }

      #$self->debug && $self->log->debug("path[$path]");

      my $find = Metabrik::Brik::File::Find->new or return $self->log->error("file::fine: new");
      $find->brik_init;
      $find->path($path);
      $find->recursive(0);

      my $found = $find->all('.*', '.*');

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$word/) {
            push @comp, $this;
         }
      }
   }

   return @comp;
}

# 1. $word - The word the user is trying to complete.
# 2. $line - The line as typed by the user so far.
# 3. $start - The offset into $line where $word starts.
# The true default completion method for Term::Shell when no comp_* matched.
# Ugly, we should merge with comp_catch_sub().
# Bug from Term::Shell: $start is not an offset in that case.
sub catch_comp {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("catch_comp: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Be default, we will read the current directory
   if (! length($start)) {
      $start = '.';
   }

   $self->debug && $self->log->debug("catch_comp: DEFAULT: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   my @comp = ();

   # We don't use $start here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $context->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         #$self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      #my $home = $self->path_home;
      my $home = $self->{path_home};
      $start =~ s/^~/$home/;

      if ($start =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }
      $self->debug && $self->log->debug("path[$path]");

      my $find = Metabrik::Brik::File::Find->new or return $self->log->error("file::fine: new");
      $find->brik_init;
      $find->path($path);
      $find->recursive(0);

      my $found = $find->all('.*', '.*');

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }

   return @comp;
}

1;

__END__
