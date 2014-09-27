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
   mebyrc
   meby_history
   ps1
   title

   echo
   debug
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
our $CONTEXT;

#use vars qw{$AUTOLOAD};

#sub AUTOLOAD {
#   my $self = shift;

#   $self->log->debug("autoload[$AUTOLOAD]");
#   $self->log->debug("self[$self]");

#   $self->ps_update_prompt('xxx $AUTOLOAD ');
#   #$self->ps1('$AUTOLOAD ');
#   $self->ps_update_prompt;

#   return 1;
#}

{
   no warnings;

   # We rewrite the log accessor
   *log = sub {
      return $CONTEXT->loaded->{'core::context'}->log;
   };
}

#
# Term::Shell::main stuff
#
sub init {
   my $self = shift;

   $|++;

   $self->ps_set_path_home;
   $self->ps_set_signals;
   $self->ps_update_path_cwd;
   $self->ps_update_prompt;

   my $rc = $self->mebyrc($self->path_home."/.mebyrc");
   my $history = $self->meby_history($self->path_home."/.meby_history");

   if (-f $rc) {
      open(my $in, '<', $rc)
         or $self->log->fatal("init: can't open rc file [$rc]: $!");
      while (defined(my $line = <$in>)) {
         next if ($line =~ /^\s*#/);  # Skip comments
         chomp($line);
         $self->cmd($self->ps_lookup_vars_in_line($line));
      }
      close($in);
   }

   # Default: 'us,ue,md,me', see `man 5 termcap' and Term::Cap
   # See also Term::ReadLine LoadTermCap() and ornaments() subs.
   $self->term->ornaments('md,me');

   if ($self->term->can('ReadHistory')) {
      if (-f $history) {
         #print "DEBUG: ReadHistory\n";
         $self->term->ReadHistory($history)
            or $self->log->fatal("init: can't read history file [$history]: $!");
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

   return $self->ps1;
}

sub cmdloop {
   my $self = shift;

   $self->{stop} = 0;
   $self->preloop;

   my @lines = ();
   while (defined(my $line = $self->readline($self->prompt_str))) {
      $line = $self->ps_lookup_vars_in_line($line);
      push @lines, $line;

      if ($line =~ /\\\s*$/) {
         $self->ps_update_prompt('.. ');
         next;
      }

      # Multiline edition finished, we can remove the `\' char before joining
      for (@lines) {
         s/\\\s*$//;
      }

      $self->debug && $self->log->debug("cmdloop: lines[@lines]");

      $self->cmd(join('', @lines));
      @lines = ();
      $self->ps_update_prompt;

      last if $self->{stop};
   }

   $self->run_exit;

   return $self->postloop;
}

#
# Metabricky::Brick::Shell::Meby stuff
#
sub ps_set_title {
   my $self = shift;
   my ($title) = @_;

   print "\c[];$title\a";

   return $self->title($title);
}

sub ps_lookup_vars_in_line {
   my $self = shift;
   my ($line) = @_;

   if ($line =~ /^\s*(?:run|set)\s+/) {
      my @t = split(/\s+/, $line);
      for my $a (@t) {
         if ($a =~ /\$([a-zA-Z0-9_]+)/) {
            my $varname = '$'.$1;
            #print "DEBUG varname[$varname]\n";

            my $result = $CONTEXT->lookup($varname) || 'undef';
            #print "result1[$line]\n";
            $line =~ s/\$${1}/$result/m;
            #print "result2[$line]\n";
         }
      }
   }

   return $line;
}

sub ps_update_path_cwd {
   my $self = shift;

   my $cwd = peu_convert_path(getcwd());
   $self->path_cwd($cwd);

   return 1;
}

sub ps_set_path_home {
   my $self = shift;

   my $home = peu_convert_path(home());
   $self->path_home($home);

   return 1;
}

sub ps_update_prompt {
   my $self = shift;
   my ($str) = @_;

   if (! defined($str)) {
      my $cwd = $self->path_cwd;
      my $home = $self->path_home;
      $cwd =~ s/$home/~/;

      my $ps1 = "meby $cwd> ";
      if ($^O =~ /win32/i) {
         $ps1 =~ s/> /\$ /;
      }
      elsif ($< == 0) {
         $ps1 =~ s/> /# /;
      }

      $self->ps1($ps1);
   }
   else {
      $self->ps1($str);
   }

   return 1;
}

sub ps_set_signals {
   my $self = shift;

   #my @signals = grep { substr($_, 0, 1) ne '_' } keys %SIG;

   #$SIG{TSTP} = sub {
      #return 1;
   #};

   #$SIG{CONT} = sub {
      #return 1;
   #};

   $SIG{INT} = sub {
      return 1;
   };

   return 1;
}

#
# Term::Shell::run stuff
#
sub run_version {
   my $self = shift;

   my $r = $CONTEXT->call(sub {
      return $_ = $Metabricky::VERSION;
   });

   return $r;
}

sub comp_version {
   return ();
}

sub run_write_history {
   my $self = shift;

   if ($self->term->can('WriteHistory') && defined($self->meby_history)) {
      my $r = $self->term->WriteHistory($self->meby_history);
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
      my %h = @_;

      my $__lp_result = {
         r => $h{out},
         a => [ split(/\n/, $h{out}) ],
      };

      for my $__lp_this (@{$__lp_result->{a}}) {
         push @{$__lp_result->{m}}, [ split(/\s+/, $__lp_this) ];
      }

      return $_ = $__lp_result;
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
      return $self->cmd($self->ps_lookup_vars_in_line($history[$c]));
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
      $self->ps_update_path_cwd;
   }
   else {
      chdir($self->path_home);
      $self->ps_update_path_cwd;
      #$self->path_cwd($self->path_home);
   }

   $self->ps_update_prompt;

   return 1;
}

# off: use catch_comp()
#sub comp_cd {
#}

sub run_pwd {
   my $self = shift;

   $self->log->info($self->path_cwd);

   return 1;
}

sub comp_pwd {
   return ();
}

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

   $self->ps_set_title($title);

   return 1;
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

      $line = $self->ps_lookup_vars_in_line($line);
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

   my $line = $self->line;

   # Line starts with a `!' char, we want to launch a shell command
   if ($line =~ /^!/) {
      $line =~ s/^!\s*//;
      return $self->run_shell(split(/\s+/, $line));
   }

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
   my $last_word = $start;

   #if (! length($last_word)) {
      #$last_word = '.';
   #}

   $self->debug && $self->log->debug("catch_comp: word[$word] line[$line] start[$start] count[$count] last_word[$last_word]");

   my @comp = ();

   if ($last_word =~ /^\$/ || $words[-1] =~ /^\$/) {
      my $variables = $CONTEXT->variables;

      (my $name = $last_word) =~ s/^\$//;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         #$self->debug && $self->log->debug("variable[$this] last_word[$last_word]");
         if ($this =~ /^$name/) {
            push @comp, $this;
         }
      }
   }
   else {
      if ($count == 1) {
         $last_word = '.';
      }

      my $path = '.';
      if (length($last_word)) {
         my $home = $self->path_home;
         $last_word =~ s/^~/$home/;
         if ($last_word =~ /^(.*)\/.*$/) {
            $path = $1 || '/';
         }
      }

      $self->debug && $self->log->debug("path[$path]");

      my $find = Metabricky::Brick::File::Find->new or return $self->log->error("file::fine: new");
      $find->init;
      $find->path($path);
      $find->recursive(0);

      my $found = $find->all('.*', '.*');

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$last_word/) {
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
