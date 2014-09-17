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

# Exists because we cannot give an argument to Term::Shell::new()
# Or I didn't found how to do it.
our $Bricks;

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
      return $Bricks->{'core::context'}->log;
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

sub ps_lookup_var {
   my $self = shift;
   my ($var) = @_;

   my $context = $Bricks->{'core::context'};

   if ($var =~ /^\$(\S+)/) {
      if (my $res = $context->do($var)) {
         $var =~ s/\$${1}/$res/;
      }
      else {
         $self->log->debug("ps_lookup_var: unable to lookup variable [$var]");
         last;
      }
   }

   return $var;
}

sub ps_lookup_vars_in_line {
   my $self = shift;
   my ($line) = @_;

   my $context = $Bricks->{'core::context'};

   if ($line =~ /^\s*(?:run|set)\s+/) {
      my @t = split(/\s+/, $line);
      for my $a (@t) {
         if ($a =~ /^\$(\S+)/) {
            if (my $res = $context->do($a)) {
               $line =~ s/\$${1}/$res/;
            }
            else {
               $self->log->debug("ps_lookup_vars_in_line: unable to lookup variable [$a]");
               last;
            }
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

my $jobs = {};

sub ps_set_signals {
   my $self = shift;

   my @signals = grep { substr($_, 0, 1) ne '_' } keys %SIG;

   $SIG{TSTP} = sub {
      if (defined($jobs->{current})) {
         print "DEBUG SIGTSTP: ".$jobs->{current}->pid."\n";
         $jobs->{current}->kill("SIGTSTP");
         $jobs->{current}->kill("SIGINT");
         return 1;
      }
   };

   $SIG{CONT} = sub {
      if (defined($jobs->{current})) {
         print "DEBUG SIGCONT: ".$jobs->{current}->pid."\n";
         $jobs->{current}->kill("SIGCONT");
         return 1;
      }
   };

   $SIG{INT} = sub {
      if (defined($jobs->{current})) {
         print "DEBUG SIGINT: ".$jobs->{current}->pid."\n";
         $jobs->{current}->kill("SIGINT");
         undef $jobs->{current};
         return 1;
      }
   };

   return 1;
}

#
# Term::Shell::run stuff
#
sub run_version {
   my $self = shift;

   my $context = $Bricks->{'core::context'};

   $context->call(sub {
      return $_ = $Metabricky::VERSION;
   }) or return;

   return 1;
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

sub run_exit {
   my $self = shift;

   $self->run_write_history;

   return $self->stoploop;
}

# For shell commands that do not need a terminal
sub run_shell {
   my $self = shift;
   my (@args) = @_;

   my $context = $Bricks->{'core::context'};

   my $out = '';
   eval {
      IPC::Run::run(\@args, \undef, \$out);
   };
   if ($@) {
      return $self->log->error("run_shell: $@");
   }

   $context->call(sub {
      my %h = @_;

      return $_ = $h{out};
   }, out => $out) or return;

   print $out;

   return 1;
}

# For external commands that need a terminal (vi, for instance)
sub run_system {
   my $self = shift;
   my (@args) = @_;

   return system(@args);
}

# XXX: should be a shell alias
sub run_ls {
   my $self = shift;

   if ($^O =~ /win32/i) {
      return $self->run_shell('dir', @_);
   }
   else {
      return $self->run_shell('ls', '-lF', @_);
   }
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
         print "[$c] $_\n";
         $c++;
      }
   }

   return 1;
}

# XXX: should be a brick, and run_save an alias.
sub run_save {
   my $self = shift;
   my ($data, $file) = @_;

   if (! defined($file)) {
      $self->log->error("save: pass \$data and \$file parameters");
      return;
   }

   $data = $self->ps_lookup_var($data);

   my $r = open(my $out, '>', $file);
   if (!defined($r)) {
      $self->log->error("save: unable to open file [$file] for writing: $!");
      return;
   }
   print $out $data;
   close($out);

   return 1;
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   if (defined($dir)) {
      if (! -d $dir) {
         $self->log->error("cd: $dir: can't cd to this");
         return;
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

sub run_pwd {
   my $self = shift;

   print $self->path_cwd."\n";

   return 1;
}

sub run_pl {
   my $self = shift;

   my $context = $Bricks->{'core::context'};

   my $line = $self->line;
   $line =~ s/^pl\s+//;

   $self->debug && $self->log->debug("run_pl: code[$line]");

   my $r = $context->do($line, $self->echo);
   if (! defined($r)) {
      $self->log->error("pl: unable to execute Code [$line]");
      return;
   }

   if ($self->echo) {
      print "$r\n";
   }

   return $r;
}

sub run_su {
   my $self = shift;
   my ($cmd, @args) = @_;

   #print "[DEBUG] cmd[$cmd] args[@args]\n";
   if (defined($cmd)) {
      system('sudo', $cmd, @args);
   }
   else {
      system('sudo', $0);
   }

   return 1;
}

sub run_reload {
   my $self = shift;

   my $reloaded = Module::Reload->check;
   if ($reloaded) {
      $self->log->info("reload: some modules were reloaded");
   }

   return 1;
}

sub run_load {
   my $self = shift;
   my ($brick) = @_;

   my $context = $Bricks->{'core::context'};

   my $r = $context->load($brick) or return;
   if ($r) {
      $self->log->verbose("load: Brick [$brick] loaded");
   }

   return $r;
}

sub run_show {
   my $self = shift;

   my $context = $Bricks->{'core::context'};

   my $status = $context->status;

   print "Available bricks:\n";

   my $total = 0;
   my $count = 0;
   print "   Loaded:\n";
   for my $loaded (@{$status->{loaded}}) {
      print "      $loaded\n";
      $count++;
      $total++;
   }
   print "   Count: $count\n";

   $count = 0;
   print "   Not loaded:\n";
   for my $notloaded (@{$status->{notloaded}}) {
      print "      $notloaded\n";
      $count++;
      $total++;
   }
   print "   Count: $count\n";

   print "Total: $total\n";

   return 1;
}

sub run_set {
   my $self = shift;
   my ($brick, $attribute, $value) = @_;

   my $context = $Bricks->{'core::context'};

   # set is called without args, we display everything
   if (! defined($brick)) {
      my $attributes = $context->get or return;

      print "Set attribute(s):\n";

      my $count = 0;
      for my $brick (sort { $a cmp $b } keys %$attributes) {
         for my $k (sort { $a cmp $b } keys %{$attributes->{$brick}}) {
            print "   $brick $k ".$attributes->{$brick}->{$k}."\n";
            $count++;
         }
      }

      print "Total: $count\n";

      return 1;
   }
   # set is called with only a brick as an arg, we show its attributes
   elsif (defined($brick) && ! defined($attribute)) {
      my $available = $context->available or return;
      my $attributes = $context->get or return;

      if (! exists($available->{$brick})) {
         $self->log->error("set: Brick [$brick] does not exist");
         return;
      }

      print "Set attribute(s) for Brick [$brick]:\n";

      my $count = 0;
      for my $k (sort { $a cmp $b } keys %{$attributes->{$brick}}) {
         print "   $brick $k ".$attributes->{$brick}->{$k}."\n";
         $count++;
      }

      print "Total: $count\n";

      return 1;
   }
   # set is called with is a brick and a key without value
   elsif (defined($brick) && defined($attribute) && ! defined($value)) {
      my $available = $context->available or return;
      my $attributes = $context->get or return;

      if (! exists($available->{$brick})) {
         $self->log->error("set: Brick [$brick] does not exist");
         return;
      }

      if (! exists($attributes->{$brick}->{$attribute})) {
         $self->log->error("set: Attribute [$attribute] does not exist for Brick [$brick]");
         return;
      }

      print "Set attribute [$attribute] for Brick [$brick]:\n";

      print "   $brick $attribute ".$attributes->{$brick}->{$attribute}."\n";

      return 1;
   }
   # set is called with all args (brick, key, value)
   else {
      my $r = $context->set($brick, $attribute, $value);
      if (! defined($r)) {
         $self->log->error("set: unable to set Brick [$brick] Attribute [$attribute] to Value [$value]");
         return;
      }

      return $r;
   }

   return 1;
}

sub run_run {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   if (! defined($brick) || ! defined($command)) {
      $self->log->info("run [brick] [command] <[arg1 arg2 .. argN]>");
      return;
   }

   my $context = $Bricks->{'core::context'};

   my $r = $context->run($brick, $command, @args);
   if (! defined($r)) {
      $self->log->error("run: unable to execute Command [$command] for Brick [$brick]");
      return;
   }

   if ($self->echo) {
      print "$r\n";
   }

   return $r;
}

sub run_title {
   my $self = shift;
   my ($title) = @_;

   $self->ps_set_title($title);

   return 1;
}

sub run_script {
   my $self = shift;
   my ($script) = @_;

   if (! defined($script)) {
      $self->log->error("script: you must provide a script to run");
      return;
   }

   if (! -f $script) {
      $self->log->error("script: script [$script] is not a file");
      return;
   }

   open(my $in, '<', $script)
      or die("[FATAL] ext::shell::run_script: can't open file [$script]: $!\n");
   while (defined(my $line = <$in>)) {
      next if ($line =~ /^\s*#/);  # Skip comments
      chomp($line);
      $self->cmd($self->ps_lookup_vars_in_line($line));
   }
   close($in);

   return 1;
}

sub help_script {
   <<'END';
execute Metabricky commands as contained in the specified script
END
}

sub smry_script {
   "execute Metabricky commands as contained in the specified script"
}

#
# Term::Shell::catch stuff
#
sub catch_run {
   my $self = shift;
   my (@args) = @_;

   my $context = $Bricks->{'core::context'};

   my $line = $self->line;

   if ($line =~ /^!/) {
      $line =~ s/^!\s*//;
      return $self->run_shell(split(/\s+/, $line));
   }

   my $available = $context->available or return;
   if (defined($available)) {
      for my $brick (keys %$available) {
         if ($args[0] eq $brick) {
            print "DEBUG match[$brick]\n";
            #$self->ps_update_prompt("[$brick]> ");
            #$self->ps_update_prompt;
            #return $self->run_shell(@args);
         }
      }
   }

   # Default to execute Perl commands
   return $self->run_pl(@args);
}

# XXX: move in Metabricky::Ext
sub _ioa_dirsfiles {
   my $self = shift;
   my ($dir, $grep) = @_;

   #print "\nDIR[$dir]\n";

   my @dirs = ();
   eval {
      @dirs = io($dir)->all_dirs;
   };
   if ($@) {
      chomp($@);
      $self->log->error("$dir: dirs: $@");
      return [], [];
   }

   my @files = ();
   eval {
      @files = io($dir)->all_files;
   };
   if ($@) {
      chomp($@);
      $self->log->error("$dir: files: $@");
      return [], [];
   }

   #@dirs = map { $_ =~ s/^\///; $_ } @dirs;  # Remove leading slash
   #@files = map { $_ =~ s/^\///; $_ } @files;  # Remove leading slash
   @dirs = map { s/^\.\///; s/$/\//; $_ } @dirs;  # Remove leading slash, add a trailing /
   @files = map { s/^\.\///; $_ } @files;  # Remove leading slash

   #print "before[@dirs|@files]\n";

   if (defined($grep)) {
      @dirs = grep(/^$grep/, @dirs);
      @files = grep(/^$grep/, @files);
   }

   #print "after[@dirs|@files]\n";

   return \@dirs, \@files;
}

#
# Term::Shell::comp stuff
#
sub comp_run {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $Bricks->{'core::context'};

   my @words = split(/\s+/, $line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $shell_command = defined($words[0]) ? $words[0] : undef;
   my $brick = defined($words[1]) ? $words[1] : undef;
   my $brick_command = defined($words[2]) ? $words[2] : undef;

   my @comp = ();

   # Two words or less entered on command line, we check the second one for completion
   if ($count == 1 || $count <= 2 && length($word) > 0) {
      my $available = $context->available or return;
      if (! defined($available)) {
         $self->log->warning("comp_run: can't fetch available Bricks");
         return ();
      }

      for my $a (keys %$available) {
         #if ($self->debug) {
            #$self->log->debug("[$a] [$word]");
         #}
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # Second word found or third word started, we search against available Brick Commands
   elsif ($count == 2 && length($word) == 0) {
      if (! exists($Bricks->{$brick})) {
         $self->log->verbose("Brick [$brick] not loaded");
         return;
      }

      my $commands = $Bricks->{$brick}->get_commands;
      push @comp, @$commands;
   }
   elsif ($count == 3) {
      my $commands = $Bricks->{$brick}->get_commands;

      for my $a (@$commands) {
         if ($a =~ /^$word/) {
            push @comp, $a; 
         }
      }
   }

   return @comp;
}

sub comp_set {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $Bricks->{'core::context'};

   my @words = split(/\s+/, $line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $shell_command = defined($words[0]) ? $words[0] : undef;
   my $brick = defined($words[1]) ? $words[1] : undef;
   my $brick_attribute = defined($words[2]) ? $words[2] : undef;

   my @comp = ();

   if ($count == 1 || $count == 2 && length($word) > 0) {
      my $available = $context->available or return;
      if (! defined($available)) {
         $self->log->warning("comp_run: can't fetch available Bricks");
         return ();
      }

      for my $a (keys %$available) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   elsif ($count == 2 && length($word) == 0) {
      if (! exists($Bricks->{$brick})) {
         $self->log->verbose("Brick [$brick] not loaded");
         return;
      }

      my $attributes = $Bricks->{$brick}->get_attributes;
      push @comp, @$attributes;
   }
   elsif ($count == 3 && length($word) > 0) {
      my $attributes = $Bricks->{$brick}->get_attributes;

      for my $a (@$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }

   return @comp;
}

sub comp_load {
   return shift->comp_run(@_);
}

# Default to check for global completion value
sub catch_comp {
   my $self = shift;
   my ($word, $line, $start) = @_;

   $self->debug && $self->log->debug("catch_comp: word[$word] line[$line] start[$start]");

   my $dir = '.';
   if (defined($line)) {
      my $home = $self->path_home;
      $line =~ s/^~/$home/;
      if ($line =~ /^(.*)\/.*$/) {
         $dir = $1 || '/';
      }
   }

   $self->debug && $self->log->debug("catch_comp: DIR[$dir]");

   my ($dirs, $files) = $self->_ioa_dirsfiles($dir, $line);

   return @$dirs, @$files;
}

1;

__END__

=head1 NAME

Metabricky::Ext::Shell - Term::Shell extention

=head1 SYNOPSIS

   XXX: TODO

=head1 DESCRIPTION

Interactive use of the Metabricky shell.

=head2 GLOBAL VARIABLES

=head3 B<$Metabricky::Ext::Shell::Bricks>

=head2 COMMANDS

=head3 B<new>

=head1 SEE ALSO

L<Metabricky::Log>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
