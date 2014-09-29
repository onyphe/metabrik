#
# $Id$
#
package Metabricky::Ext::Shell;
use strict;
use warnings;

use base qw(Term::Shell Class::Gomor::Hash);

our @AS = qw(
   path_home
   path_cwd
   prompt
   rc_file
   history_file
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
use Module::Reload;
use IPC::Run;

use Metabricky;
use Metabricky::Ext::Utils qw(peu_convert_path);
use Metabricky::Brick::File::Find;

# Exists because we cannot give an argument to Term::Shell::new()
# Or I didn't found how to do it.
our $CONTEXT = {};
our $LoadRcFile = 1;
our $LoadHistoryFile = 1;
our $AUTOLOAD;

sub AUTOLOAD {
   my $self = shift;
   my (@args) = @_;

   if ($AUTOLOAD !~ /^Metabricky::Ext::Shell::run_/) {
      return 1;
   }

   (my $alias = $AUTOLOAD) =~ s/^Metabricky::Ext::Shell:://;

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
      return $CONTEXT->log;
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

      my $prompt = "meby $cwd> ";
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

            my $result = $CONTEXT->lookup($varname) || 'undef';
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

   my $rc_file = $self->rc_file($self->path_home."/.meby_rc");
   my $history_file = $self->history_file($self->path_home."/.meby_history");


   if ($LoadRcFile && -f $rc_file) {
      open(my $in, '<', $rc_file)
         or $self->log->fatal("init: can't open rc file [$rc_file]: $!");
      while (defined(my $line = <$in>)) {
         next if ($line =~ /^\s*#/);  # Skip comments
         chomp($line);
         $self->cmd($line);
      }
      close($in);
   }

   # Default: 'us,ue,md,me', see `man 5 termcap' and Term::Cap
   # See also Term::ReadLine LoadTermCap() and ornaments() subs.
   $self->term->ornaments('md,me');

   if ($LoadHistoryFile && $self->term->can('ReadHistory')) {
      if (-f $history_file) {
         #print "DEBUG: ReadHistory\n";
         $self->term->ReadHistory($history_file)
            or $self->log->fatal("init: can't read history file [$history_file]: $!");
      }
   }

   # They are loaded when core::context init is performed
   # Should be placed in core::context Brick instead of here
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
sub run_write_history {
   my $self = shift;

   if ($self->term->can('WriteHistory') && defined($self->history_file)) {
      my $r = $self->term->WriteHistory($self->history_file);
      if (! defined($r)) {
         $self->log->error("write_history: unable to write history file");
         return;
      }
      #print "DEBUG: WriteHistory ok\n";
   }

   return 1;
}

sub comp_write_history {
   return ();
}

sub run_exit {
   my $self = shift;

   $self->run_write_history;

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

   $CONTEXT->call(sub {
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

   my @history = $self->term->GetHistory;
   if (defined($c)) {
      return $self->cmd($history[$c]);
   }
   else {
      my $c = 0;
      for (@history) {
         $self->log->info("[$c] $_");
         $c++;
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

   my $r = $CONTEXT->do($line, $self->echo);
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

   my $reloaded = Module::Reload->check;
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
   my ($brick) = @_;

   if (! defined($brick)) {
      return $self->log->info("load <brick>");
   }

   my $r = $CONTEXT->load($brick) or return;
   if ($r) {
      $self->log->verbose("load: Brick [$brick] loaded");
   }

   $self->add_handler("run_$brick");

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

   # We want to find available bricks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      my $available = $CONTEXT->available;
      if ($self->debug && ! defined($available)) {
         $self->log->debug("\ncomp_load: can't fetch available Bricks");
         return ();
      }

      for my $a (keys %$available) {
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_show {
   my $self = shift;

   my $status = $CONTEXT->status;

   $self->log->info("Available bricks:");

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
   my ($brick) = @_;

   if (! defined($brick)) {
      return $self->SUPER::run_help;
   }
   else {
      if ($CONTEXT->is_loaded($brick)) {
         my $attributes = $CONTEXT->loaded->{$brick}->attributes;
         my $commands = $CONTEXT->loaded->{$brick}->commands;

         for my $attribute (@$attributes) {
            my $help = $CONTEXT->loaded->{$brick}->help_set($attribute);
            $self->log->info($help) if defined($help);
         }

         for my $command (@$commands) {
            my $help = $CONTEXT->loaded->{$brick}->help_run($command);
            $self->log->info($help) if defined($help);
         }
      }
      else {
         # We return to standard help() method
         return $self->SUPER::run_help($brick);
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

   # We want to find help for loaded bricks by using completion
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
   my ($brick, $attribute, $value) = @_;

   if (! defined($brick) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info("set <brick> <attribute> <value>");
   }

   my $r = $CONTEXT->set($brick, $attribute, $value);
   if (! defined($r)) {
      return $self->log->error("set: unable to set Attribute [$attribute] for Brick [$brick]");
   }

   return $r;
}

sub comp_set {
   my $self = shift;
   my ($word, $line, $start) = @_;

   # Completion is for loaded Bricks only
   my $loaded = $CONTEXT->loaded;
   if (! defined($loaded)) {
      $self->debug && $self->log->debug("comp_set: can't fetch loaded Bricks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $brick = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for loaded Bricks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$loaded) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brick Attributes
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brick})) {
            $self->log->debug("comp_set: Brick [$brick] not loaded");
            return ();
         }
      }

      my $attributes = $loaded->{$brick}->attributes;
      push @comp, @$attributes;
   }
   # We want to complete entered Attribute
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brick})) {
            $self->log->debug("comp_set: Brick [$brick] not loaded");
            return ();
         }
      }

      my $attributes = $loaded->{$brick}->attributes;

      for my $a (@$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   elsif ($count == 3 || $count == 4 && length($word) > 0) {
      # Default completion method, we strip first three words "set <brick> <attribute>"
      shift @words;
      shift @words;
      shift @words;
      return $self->catch_comp($word, join(' ', @words), $start);
   }

   return @comp;
}

sub run_get {
   my $self = shift;
   my ($brick, $attribute) = @_;

   # get is called without args, we display everything
   if (! defined($brick)) {
      my $loaded = $CONTEXT->loaded or return;

      for my $brick (sort { $a cmp $b } keys %$loaded) {
         my $attributes = $loaded->{$brick}->attributes or next;
         for my $attribute (sort { $a cmp $b } @$attributes) {
            $self->log->info("$brick $attribute ".$CONTEXT->get($brick, $attribute));
         }
      }
   }
   # get is called with only a Brick as an arg, we show its Attributes
   elsif (defined($brick) && ! defined($attribute)) {
      my $loaded = $CONTEXT->loaded or return;

      if (! exists($loaded->{$brick})) {
         return $self->log->error("get: Brick [$brick] not loaded");
      }

      my %printed = ();
      my $attributes = $loaded->{$brick}->attributes;
      for my $attribute (sort { $a cmp $b } @$attributes) {
         my $print = "$brick $attribute ".$CONTEXT->get($brick, $attribute);
         $self->log->info($print) if ! exists($printed{$print});
         $printed{$print}++;
      }
   }
   # get is called with is a Brick and an Attribute
   elsif (defined($brick) && defined($attribute)) {
      my $loaded = $CONTEXT->loaded or return;

      if (! exists($loaded->{$brick})) {
         return $self->log->error("get: Brick [$brick] not loaded");
      }

      my $attributes = $loaded->{$brick}->attributes or return;

      if (! $loaded->{$brick}->can($attribute)) {
         return $self->log->error("get: Attribute [$attribute] does not exist for Brick [$brick]");
      }

      $self->log->info("$brick $attribute ".$CONTEXT->get($brick, $attribute));
   }

   return 1;
}

sub comp_get {
   my $self = shift;

   return $self->comp_set(@_);
}

sub run_run {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   if (! defined($brick) || ! defined($command)) {
      return $self->log->info("run <brick> <command> [ <arg1> <arg2> .. <argN> ]");
   }

   my $r = $CONTEXT->run($brick, $command, @args);
   if (! defined($r)) {
      return $self->log->error("run: unable to execute Command [$command] for Brick [$brick]");
   }

   if ($self->echo) {
      print "$r\n";
   }

   return $r;
}

sub comp_run {
   my $self = shift;
   my ($word, $line, $start) = @_;

   # Completion is for loaded Bricks only
   my $loaded = $CONTEXT->loaded;
   if (! defined($loaded)) {
      $self->debug && $self->log->debug("comp_run: can't fetch loaded Bricks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $brick = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for loaded Bricks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$loaded) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brick Commands
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brick})) {
            $self->log->debug("comp_run: Brick [$brick] not loaded");
            return ();
         }
      }

      my $commands = $loaded->{$brick}->commands;
      my $attributes = $loaded->{$brick}->attributes;
      push @comp, @$commands;
      push @comp, @$attributes;
   }
   # We want to complete entered Command and Attributes
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($loaded->{$brick})) {
            $self->log->debug("comp_run: Brick [$brick] not loaded");
            return ();
         }
      }

      my $commands = $loaded->{$brick}->commands;
      my $attributes = $loaded->{$brick}->attributes;

      for my $a (@$commands, @$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   elsif ($count == 3 || $count == 4 && length($word) > 0) {
      # Default completion method, we strip first three words "run <brick> <command>"
      shift @words;
      shift @words;
      shift @words;
      return $self->catch_comp($word, join(' ', @words), $start);
   }

   return @comp;
}

sub run_title {
   my $self = shift;
   my ($title) = @_;

   if (! defined($title)) {
      return $self->log->info("title <title>");
   }

   print "\c[];$title\a";

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
      return $self->log->error("script: script [$script] is not a file");
   }

   open(my $in, '<', $script)
      or return $self->log->error("run_script: can't open file [$script]: $!");

   my @lines = ();
   while (defined(my $line = <$in>)) {
      next if ($line =~ /^\s*#/);  # Skip comments
      chomp($line);

      # Exit?
      if ($line =~ /^exit$/) {
         $self->cmd($line);
         last;
      }

      push @lines, $line;

      if ($line =~ /\\\s*$/) {
         next;
      }

      # Multiline edition finished, we can remove the `\' char before joining
      for (@lines) {
         s/\\\s*$//;
      }

      $self->debug && $self->log->debug("run_script: lines[@lines]");

      $self->cmd(join('', @lines));
      @lines = ();
   }

   close($in);

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
      my $variables = $CONTEXT->variables;

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

      my $home = $self->path_home;
      $start =~ s/^~/$home/;

      if ($start =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }

      $self->debug && $self->log->debug("path[$path]");

      my $find = Metabricky::Brick::File::Find->new or return $self->log->error("file::fine: new");
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

Metabricky::Ext::Shell - extension using Term::Shell as a base class

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
