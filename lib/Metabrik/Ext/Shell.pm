#
# $Id$
#
package Metabrik::Ext::Shell;
use strict;
use warnings;

use base qw(CPAN::Term::Shell CPAN::Class::Gomor::Hash);

our @AS = qw(
   path_home
   path_cwd
   prompt
   title
   echo
   debug
   _aliases
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Cwd;
use Data::Dumper;
use File::HomeDir qw(home);
use IO::All;
use CPAN::Module::Reload;
use IPC::Run;

use Metabrik;
use Metabrik::Ext::Utils qw(peu_convert_path);
use Metabrik::Brik::File::Find;

# Exists because we cannot give an argument to Term::Shell::new()
# Or I didn't found how to do it.
our $CTX = {};
our $AUTOLOAD;

sub AUTOLOAD {
   my $self = shift;
   my (@args) = @_;

   if ($AUTOLOAD !~ /^Metabrik::Ext::Shell::run_/) {
      return 1;
   }

   (my $alias = $AUTOLOAD) =~ s/^Metabrik::Ext::Shell:://;

   if ($self->debug) {
      $self->log->debug("autoload[$AUTOLOAD]");
      $self->log->debug("alias[$alias]");
      $self->log->debug("args[@args]");
   }

   my $aliases = $self->_aliases;
   if (exists($aliases->{$alias})) {
      my $cmd = $aliases->{$alias};
      return $self->cmd(join(' ', $cmd, @args));
   }

   return 1;
}

{
   no warnings;

   # We rewrite the log accessor
   *log = sub {
      return $CTX->log;
   };
}

#
# Term::Shell::main stuff
#
sub _update_path_home {
   my $self = shift;

   $self->path_home(peu_convert_path(home()));

   return 1;
}

sub _update_path_cwd {
   my $self = shift;

   my $cwd = peu_convert_path(getcwd());
   my $home = $self->path_home;
   $cwd =~ s/^$home/~/;

   $self->path_cwd($cwd);

   return 1;
}

sub _update_prompt {
   my $self = shift;
   my ($prompt) = @_;

   if (defined($prompt)) {
      $self->prompt($prompt);
   }
   else {
      my $cwd = $self->path_cwd;

      my $prompt = "meta $cwd> ";
      if ($^O =~ /win32/i) {
         $prompt =~ s/> /\$ /;
      }
      elsif ($< == 0) {
         $prompt =~ s/> /# /;
      }

      $self->prompt($prompt);
   }

   return 1;
}

sub _off_lookup_variables {
   my $self = shift;
   my ($line) = @_;

   my @words = $self->line_parsed($line);
   my $word = $words[0];

   # We lookup variables only for run and set shell Commands
   if (defined($word) && $word =~ /^(?:run|set)$/) {
      for my $this (@words) {
         if ($this =~ /\$([a-zA-Z0-9_]+)/) {
            my $varname = '$'.$1;
            $self->debug && $self->log->debug("lookup: varname[$varname]");

            my $result = $CTX->lookup($varname) || 'undef';
            #$self->debug && $self->log->debug("lookup: result1[$line]");
            $self->debug && $self->log->debug("lookup: result1[..]");
            $line =~ s/\$${1}/$result/;
            #$self->debug && $self->log->debug("lookup: result2[$line]");
            $self->debug && $self->log->debug("lookup: result2[..]");
         }
      }
   }

   return $line;
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

   if ($CTX->is_loaded('shell::rc')) {
      my $cmd = $CTX->run('shell::rc', 'load');
      for (@$cmd) {
         $self->cmd($_);
      }
   }

   # Default: 'us,ue,md,me', see `man 5 termcap' and Term::Cap
   # See also Term::ReadLine LoadTermCap() and ornaments() subs.
   $self->term->ornaments('md,me');

   if ($CTX->is_loaded('shell::history')) {
      if ($CTX->get('shell::history', 'shell') eq 'undef') {
         $CTX->set('shell::history', 'shell', $self);
      }
      $CTX->run('shell::history', 'load');
   }

   # They are loaded when core::context init is performed
   # Should be placed in core::context Brik instead of here
   $self->add_handler('run_core::log');
   $self->add_handler('run_core::context');
   $self->add_handler('run_core::global');

   return $self;
}

sub prompt_str {
   my $self = shift;

   return $self->prompt;
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

   if ($CTX->is_loaded('shell::history')) {
      $CTX->run('shell::history', 'write');
   } 

   return $self->stoploop;
}

sub comp_exit {
   return ();
}

sub run_alias {
   my $self = shift;
   my ($alias, @cmd) = @_;

   my $aliases = $self->_aliases;

   if (! defined($alias)) {
      for my $this (keys %$aliases) {
         (my $alias = $this) =~ s/^run_//;
         $self->log->info(sprintf("%-10s \"%s\"", $alias, $aliases->{$this}));
      }

      return 1;
   }

   $aliases->{"run_$alias"} = join(' ', @cmd);
   $self->_aliases($aliases);

   $self->add_handler("run_$alias");

   return 1;
}

sub comp_alias {
   return ();
}

# For shell commands that do not need a terminal
sub run_shell {
   my $self = shift;
   my (@args) = @_;

   if (@args == 0) {
      return $self->log->info("shell <command> [ <arg1:arg2:..:argN> ]");
   }

   my $out = '';
   eval {
      IPC::Run::run(\@args, \undef, \$out);
   };
   if ($@) {
      return $self->log->error("run_shell: $@");
   }

   $CTX->call(sub {
      my %args = @_;

      return my $SHELL = $args{out};
   }, out => $out);

   print $out;

   return 1;
}

sub comp_shell {
   my $self = shift;

   # XXX: use $ENV{PATH} to gather binaries

   return ();
}

# For external commands that need a terminal (vi, for instance)
sub run_system {
   my $self = shift;
   my (@args) = @_;

   if (@args == 0) {
      return $self->log->info("system <command> [ <arg1:arg2:..:argN> ]");
   }

   return system(@args);
}

sub comp_system {
   my $self = shift;

   return $self->comp_shell(@_);
}

sub run_history {
   my $self = shift;
   my ($c) = @_;

   if (! $CTX->is_loaded('shell::history')) {
      return 1;
   }

   # We want to exec some history command(s)
   if (defined($c)) {
      my $history = [];
      if ($c =~ /^\d+$/) {
         $history = $CTX->run('shell::history', 'get_one', $c);
         $self->cmd($history);
      }
      elsif ($c =~ /^\d+\.\.\d+$/) {
         $history = $CTX->run('shell::history', 'get_range', $c);
         for (@$history) {
            $self->cmd($_);
         }
      }
   }
   # We just want to display history
   else {
      my $history = $CTX->run('shell::history', 'get');
      my $count = 0;
      for (@$history) {
         $self->log->info("[".$count++."] $_");
      }
   }

   return 1;
}

sub comp_history {
   return ();
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   if (defined($dir)) {
      if ($dir =~ /^~$/) {
         $dir = $self->path_home;
      }
      if (! -d $dir) {
         return $self->log->error("cd: $dir: can't cd to this");
      }
      chdir($dir);
      $self->_update_path_cwd;
   }
   else {
      chdir($self->path_home);
      $self->_update_path_cwd;
   }

   $self->_update_prompt;

   return 1;
}

# off: use catch_comp()
#sub comp_cd {
#}

sub run_pl {
   my $self = shift;

   my $line = $self->line;
   $line =~ s/^pl\s+//;

   $self->debug && $self->log->debug("run_pl: code[$line]");

   my $r = $CTX->do($line, $self->echo);
   if (! defined($r)) {
      # When ext::shell:echo is off, we can get undef and it is not an error.
      # XXX: we should use $@ to know if there is an error
      #$self->log->error("pl: unable to execute Code [$line]");
      return;
   }

   if ($self->echo) {
      print "$r\n";
   }

   return $r;
}

# off: use catch_comp()
#sub comp_pl {
#}

sub run_su {
   my $self = shift;
   my ($cmd, @args) = @_;

   # sudo not supported on Windows 
   if ($^O !~ /win32/i) {
      if (defined($cmd)) {
         system('sudo', $cmd, @args);
      }
      else {
         system('sudo', $0);
      }
   }

   return 1;
}

sub comp_su {
   return ();
}

sub run_reload {
   my $self = shift;

   my $reloaded = CPAN::Module::Reload->check;
   if ($reloaded) {
      $self->log->info("reload: some modules were reloaded");
   }

   return 1;
}

sub comp_reload {
   return ();
}

sub run_load {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->info("load <brik>");
   }

   my $r = $CTX->load($brik) or return;
   if ($r) {
      $self->log->verbose("load: Brik [$brik] loaded");
   }

   $self->add_handler("run_$brik");

   return $r;
}

sub comp_load {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find available briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      my $available = $CTX->available;
      if ($self->debug && ! defined($available)) {
         $self->log->debug("\ncomp_load: can't fetch available Briks");
         return ();
      }

      # Do not keep already loaded briks
      my $loaded = $CTX->loaded;
      for my $a (keys %$available) {
         next if $loaded->{$a};
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_show {
   my $self = shift;

   my $status = $CTX->status;

   $self->log->info("Available briks:");

   my $total = 0;
   my $count = 0;
   $self->log->info("   Loaded:");
   for my $loaded (@{$status->{loaded}}) {
      $self->log->info("      $loaded");
      $count++;
      $total++;
   }
   $self->log->info("   Count: $count");

   $count = 0;
   $self->log->info("   Not loaded:");
   for my $notloaded (@{$status->{notloaded}}) {
      $self->log->info("      $notloaded");
      $count++;
      $total++;
   }
   $self->log->info("   Count: $count");

   $self->log->info("Total: $total");

   return 1;
}

sub comp_show {
   return ();
}

sub run_help {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->SUPER::run_help;
   }
   else {
      if ($CTX->is_loaded($brik)) {
         my $attributes = $CTX->loaded->{$brik}->attributes;
         my $commands = $CTX->loaded->{$brik}->commands;

         for my $attribute (@$attributes) {
            my $help = $CTX->loaded->{$brik}->help_set($attribute);
            $self->log->info($help) if defined($help);
         }

         for my $command (@$commands) {
            my $help = $CTX->loaded->{$brik}->help_run($command);
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

   # We want to find help for loaded briks by using completion
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

   if (! defined($brik) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info("set <brik> <attribute> <value>");
   }

   my $r = $CTX->set($brik, $attribute, $value);
   if (! defined($r)) {
      return $self->log->error("set: unable to set Attribute [$attribute] for Brik [$brik]");
   }

   return $r;
}

sub comp_set {
   my $self = shift;
   my ($word, $line, $start) = @_;

   # Completion is for loaded Briks only
   my $loaded = $CTX->loaded;
   if (! defined($loaded)) {
      $self->debug && $self->log->debug("comp_set: can't fetch loaded Briks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for loaded Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$loaded) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Attributes
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not loaded");
            return ();
         }
      }

      my $attributes = $loaded->{$brik}->attributes;
      push @comp, @$attributes;
   }
   # We want to complete entered Attribute
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not loaded");
            return ();
         }
      }

      my $attributes = $loaded->{$brik}->attributes;

      for my $a (@$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   elsif ($count == 3 || $count == 4 && length($word) > 0) {
      # Default completion method, we strip first three words "set <brik> <attribute>"
      shift @words;
      shift @words;
      shift @words;
      return $self->catch_comp($word, join(' ', @words), $start);
   }

   return @comp;
}

sub run_get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   # get is called without args, we display everything
   if (! defined($brik)) {
      my $loaded = $CTX->loaded or return;

      for my $brik (sort { $a cmp $b } keys %$loaded) {
         my $attributes = $loaded->{$brik}->attributes or next;
         for my $attribute (sort { $a cmp $b } @$attributes) {
            $self->log->info("$brik $attribute ".$CTX->get($brik, $attribute));
         }
      }
   }
   # get is called with only a Brik as an arg, we show its Attributes
   elsif (defined($brik) && ! defined($attribute)) {
      my $loaded = $CTX->loaded or return;

      if (! exists($loaded->{$brik})) {
         return $self->log->error("get: Brik [$brik] not loaded");
      }

      my %printed = ();
      my $attributes = $loaded->{$brik}->attributes;
      for my $attribute (sort { $a cmp $b } @$attributes) {
         my $print = "$brik $attribute ".$CTX->get($brik, $attribute);
         $self->log->info($print) if ! exists($printed{$print});
         $printed{$print}++;
      }
   }
   # get is called with is a Brik and an Attribute
   elsif (defined($brik) && defined($attribute)) {
      my $loaded = $CTX->loaded or return;

      if (! exists($loaded->{$brik})) {
         return $self->log->error("get: Brik [$brik] not loaded");
      }

      my $attributes = $loaded->{$brik}->attributes or return;

      if (! $loaded->{$brik}->can($attribute)) {
         return $self->log->error("get: Attribute [$attribute] does not exist for Brik [$brik]");
      }

      $self->log->info("$brik $attribute ".$CTX->get($brik, $attribute));
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

   if (! defined($brik) || ! defined($command)) {
      return $self->log->info("run <brik> <command> [ <arg1> <arg2> .. <argN> ]");
   }

   my $r = $CTX->run($brik, $command, @args);
   if (! defined($r)) {
      return $self->log->error("run: unable to execute Command [$command] for Brik [$brik]");
   }

   if ($self->echo) {
      print "$r\n";
   }

   return $r;
}

sub comp_run {
   my $self = shift;
   my ($word, $line, $start) = @_;

   # Completion is for loaded Briks only
   my $loaded = $CTX->loaded;
   if (! defined($loaded)) {
      $self->debug && $self->log->debug("comp_run: can't fetch loaded Briks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   if ($self->debug) {
      $self->log->debug("comp_run: word[$word] line[$line] start[$start] count[$count] last[$last]");
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for loaded Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$loaded) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Commands
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not loaded");
            return ();
         }
      }

      my $commands = $loaded->{$brik}->commands;
      my $attributes = $loaded->{$brik}->attributes;
      push @comp, @$commands;
      push @comp, @$attributes;
   }
   # We want to complete entered Command and Attributes
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not loaded");
            return ();
         }
      }

      my $commands = $loaded->{$brik}->commands;
      my $attributes = $loaded->{$brik}->attributes;

      for my $a (@$commands, @$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   elsif ($count == 3 || $count == 4 && length($word) > 0) {
      # Default completion method, we strip first three words "run <brik> <command>"
      shift @words;
      shift @words;
      shift @words;
      my $line = join(' ', @words);
      #$self->log->verbose("word[$word] line[$line] start[$start] last[$last]");
      #my @new = $self->line_parsed($line);
      #$self->log->verbose("new[@new]");
      #return $self->catch_comp($word, $start, $line); #$line, $start);
      return $self->catch_comp($word, $line, $start);
   }

   return @comp;
}

sub run_title {
   my $self = shift;
   my ($title) = @_;

   if (! defined($title)) {
      return $self->log->info("title <title>");
   }

   print "\c[];$title\a\e[0m";

   return $self->title($title);
}

sub comp_title {
   return ();
}

sub run_script {
   my $self = shift;
   my ($script) = @_;

   if (! defined($script)) {
      return $self->log->info("script <file>");
   }

   if (! -f $script) {
      return $self->log->error("script: file [$script] not found");
   }

   if ($CTX->is_loaded('shell::script')) {
      $CTX->set('shell::script', 'file', $script);
      my $lines = $CTX->run('shell::script', 'load');
      for (@$lines) {
         $self->run_exit if /^exit$/;
         $self->cmd($_);
      }
   }
   else {
      return $self->log->info("script: shell::script Brik not loaded");
   }

   return 1;
}

# off: use catch_comp()
#sub comp_script {
#}

#
# Term::Shell::catch stuff
#
sub catch_run {
   my $self = shift;
   my (@args) = @_;

   # Default to execute Perl commands
   return $self->run_pl(@args);
}

# Default to check for global completion value
sub catch_comp {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   # Be default, we will read the current directory
   if (! length($start)) {
      $start = '.';
   }

   $self->debug && $self->log->debug("catch_comp: word[$word] line[$line] start[$start] count[$count]");

   my @comp = ();

   # We don't use $start here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $CTX->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         $self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      my $home = $self->path_home;
      $start =~ s/^~/$home/;

      if ($start =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }

      $self->debug && $self->log->debug("path[$path]");

      my $find = Metabrik::Brik::File::Find->new or return $self->log->error("file::fine: new");
      $find->init;
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

=head1 NAME

Metabrik::Ext::Shell - extension using Term::Shell as a base class

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
