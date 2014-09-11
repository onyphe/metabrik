#
# $Id$
#
package Metabricky::Brick::Core::Meby;
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
   context

   commands
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Cwd;
use File::HomeDir qw(home);
use IO::All;
use Module::Reload;
use IPC::Run;

use Metabricky;
use Metabricky::Brick::Core::Context;
use Metabricky::Ext::Utils qw(peu_convert_path);

# Exists because we cannot give an argument to Term::Shell::new()
# Or I didn't found how to do it.
our $Log;

use vars qw{$AUTOLOAD};

sub AUTOLOAD {
   my $self = shift;

   my $context = $self->context;

   $Log->debug("autoload[$AUTOLOAD]");
   $Log->debug("self[$self]");

   $self->ps_update_prompt('xxx $AUTOLOAD ');
   #$self->ps1('$AUTOLOAD ');
   $self->ps_update_prompt;

   return 1;
}

#
# Term::Shell::main stuff
#
sub init {
   my $self = shift;

   $|++;

   if (! defined($Log)) {
      die("[FATAL] core::meby::init: you must create a `Log' object\n");
   }

   my $context = Metabricky::Brick::Core::Context->new(
      log => $Log,
      shell => $self,
   );
   $self->context($context);

   $self->ps_set_path_home;
   $self->ps_set_signals;
   $self->ps_update_path_cwd;
   $self->ps_update_prompt;

   my $rc = $self->mebyrc($self->path_home."/.mebyrc");
   my $history = $self->meby_history($self->path_home."/.meby_history");

   if (-f $rc) {
      open(my $in, '<', $rc) or $Log->fatal("can't open rc file [$rc]: $!");
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
         $self->term->ReadHistory($history)
            or $Log->fatal("can't read history file [$history]: $!");
      }
   }

   $context->set_available_bricks
      or $Log->fatal("core::meby::init: set_available_bricks");

   # XXX: not used now
   #my $available = $context->get_available_bricks
      #or $Log->fatal("init: unable to get available bricks");
   #for my $a (keys %$available) {
      #$self->add_handlers("run_$a");
   #}

   #{
      #no strict 'refs';
      #use Data::Dumper;
      #print Dumper(\%{"Metabricky::Brick::Core::Meby::"})."\n";
      #my $commands = $self->ps_get_commands;
      #for my $command (@$commands) {
         #print "** adding command [$command]\n";
         #${"Metabricky::Brick::Core::Meby::"}{"run_$command"} = 1;
      #}
      #print Dumper(\%{"Metabricky::Brick::Core::Meby::"})."\n";
   #};

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

   my $buf = '';
   while (defined(my $line = $self->readline($self->prompt_str))) {
      $buf .= $self->ps_lookup_vars_in_line($line);

      if ($line =~ /[;{]\s*$/) {
         $self->ps_update_prompt('.. ');
         next;
      }

      $self->cmd($buf);
      $buf = '';
      $self->ps_update_prompt;

      last if $self->{stop};
   }

   return $self->postloop;
}

#
# Metabricky::Brick::Core::Meby stuff
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

   my $context = $self->context;

   if ($var =~ /^\$(\S+)/) {
      if (my $res = $context->do($var)) {
         $var =~ s/\$${1}/$res/;
      }
      else {
         $Log->warning("ps_lookup_var: unable to lookup variable [$var]");
         last;
      }
   }

   return $var;
}

sub ps_lookup_vars_in_line {
   my $self = shift;
   my ($line) = @_;

   my $context = $self->context;

   if ($line =~ /^\s*(?:run|set)\s+/) {
      my @t = split(/\s+/, $line);
      for my $a (@t) {
         if ($a =~ /^\$(\S+)/) {
            if (my $res = $context->do($a)) {
               $line =~ s/\$${1}/$res/;
            }
            else {
               $Log->warning("ps_lookup_vars_in_line: unable to lookup variable [$a]");
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

sub ps_get_commands {
   my $self = shift;

   my $context = $self->context;

   my $commands = $context->get_brick_attribute('core::global', 'commands');
   if (! defined($commands)) {
      return [];
   }

   return [ split(':', $commands) ];
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

   my $context = $self->context;

   $context->call(sub {
      return $_ = $Metabricky::VERSION;
   }) or return;

   return 1;
}

# For commands that do not need a terminal
sub run_command {
   my $self = shift;
   my (@args) = @_;

   my $context = $self->context;

   my $out = '';
   IPC::Run::run(\@args, \undef, \$out);

   $context->call(sub {
      my %h = @_;

      return $_ = $h{out};
   }, out => $out) or return;

   print $out;

   return 1;
}

# For commands that need a terminal
sub run_system {
   my $self = shift;
   my (@args) = @_;

   my $context = $self->context;

   if ($^O =~ /win32/i) {
      return system(@args);
   }
   else {
      eval("use Proc::Simple");
      if ($@) {
         chomp($@);
         $Log->fatal("can't load Proc::Simple module: $@");
         return;
      }

      my $bg = (defined($args[-1]) && $args[-1] eq '&') || 0;
      if ($bg) {
         pop @args;
      }

      my $proc = Proc::Simple->new;
      $proc->start(@args);
      $jobs->{current} = $proc;
      if (! $bg) {
         my $status = $proc->wait; # Blocking until process exists
         return $status;
      }

      return $proc;
   }

   return;
}

sub run_ls {
   my $self = shift;

   if ($^O =~ /win32/i) {
      return $self->run_command('dir', @_);
   }
   else {
      return $self->run_command('ls', '-lF', @_);
   }
}

# XXX: off for now, need to work on it
sub _run_li {
   my $self = shift;
   my (@args) = @_;

   my $cwd = $self->path_cwd;

   my @files = io($cwd)->all;
   for my $this (@files) {
      my $file = io($this);
      my $name = $file->relative;
      next if $name =~ /^\./;

      my $size = $file->size;
      my $mtime = $file->mtime;
      my $uid = $file->uid;
      my $gid = $file->gid;
      #my $modes = $file->modes;

      print "$size $mtime $uid:$gid $file\n";
   }

   return 1;
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

   my $context = $self->context;

   if (! defined($file)) {
      $Log->error("save: pass \$data and \$file parameters");
      return;
   }

   $data = $self->ps_lookup_var($data);

   my $r = open(my $out, '>', $file);
   if (!defined($r)) {
      $Log->error("save: unable to open file [$file] for writing: $!");
      return;
   }
   print $out $data;
   close($out);

   return 1;
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   my $context = $self->context;

   if (defined($dir)) {
      if (! -d $dir) {
         $Log->error("cd: $dir: can't cd to this");
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

sub run_doc {
   my $self = shift;
   my (@args) = @_;

   my $context = $self->context;

   if (! defined($args[0])) {
      $Log->error("you have to provide a module as an argument");
      return;
   }

   system('perldoc', @args);

   return 1;
}

sub run_sub {
   my $self = shift;
   my (@args) = @_;

   my $context = $self->context;

   if (! defined($args[0])) {
      $Log->error("you have to provide a function as an argument");
      return;
   }

   system('perldoc', '-f', @args);

   return 1;
}

sub run_src {
   my $self = shift;
   my (@args) = @_;

   my $context = $self->context;

   if (! defined($args[0])) {
      $Log->error("you have to provide a module as an argument");
      return;
   }

   system('perldoc', '-m', @args);

   return 1;
}

sub run_faq {
   my $self = shift;
   my (@args) = @_;

   my $context = $self->context;

   if (! defined($args[0])) {
      $Log->error("you have to provide a question as an argument");
      return;
   }

   system('perldoc', '-q', @args);

   return 1;
}

sub run_pl {
   my $self = shift;
   my (@args) = @_;

   my $context = $self->context;

   my $line = $self->line;
   #print "[DEBUG] [$line]\n";
   $line =~ s/^pl\s+//;

   my $newline = $context->get_brick_attribute('core::global', 'newline');
   if ($newline && $line =~ /^\s*print/) {
      $line .= ';print "\n";';
   }

   return $context->do($line);
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

   my $context = $self->context;

   my $reloaded = Module::Reload->check;
   if ($reloaded) {
      $Log->info("some modules were reloaded");
   }

   return 1;
}

sub run_load {
   my $self = shift;
   my ($brick) = @_;

   my $context = $self->context;

   my $r = $context->load_brick($brick) or return;
   if ($r) {
      $Log->verbose("Brick [$brick] loaded");
   }

   return $r;
}

sub run_show {
   my $self = shift;

   my $context = $self->context;

   my $loaded = $context->get_status_bricks;

   print "Available bricks:\n";

   my $total = 0;
   my $count = 0;
   print "   Loaded:\n";
   for my $loaded (@{$loaded->{loaded}}) {
      print "      $loaded\n";
      $count++;
      $total++;
   }
   print "   Count: $count\n";

   $count = 0;
   print "   Not loaded:\n";
   for my $notloaded (@{$loaded->{notloaded}}) {
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

   my $context = $self->context;

   # set is called without args, we display everything
   if (! defined($brick)) {
      my $attributes = $context->get_set_attributes or return;

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
      my $available = $context->get_available_bricks or return;
      my $attributes = $context->get_set_attributes or return;

      if (! exists($available->{$brick})) {
         $Log->error("Brick [$brick] does not exist");
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
      my $available = $context->get_available_bricks or return;
      my $attributes = $context->get_set_attributes or return;

      if (! exists($available->{$brick})) {
         $Log->error("Brick [$brick] does not exist");
         return;
      }

      if (! exists($attributes->{$brick}->{$attribute})) {
         $Log->error("Attribute [$attribute] does not exist for Brick [$brick]");
         return;
      }

      print "Set attribute [$attribute] for Brick [$brick]:\n";

      print "   $brick $attribute ".$attributes->{$brick}->{$attribute}."\n";

      return 1;
   }
   # set is called with all args (brick, key, value)
   else {
      return $context->set_brick_attribute($brick, $attribute, $value);
   }

   return 1;
}

sub run_run {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   if (! defined($brick) || ! defined($command)) {
      $Log->error("run [brick] [command] <[arg1 arg2 .. argN]>\n");
      return;
   }

   my $context = $self->context;

   return $context->execute_brick_command($brick, $command, @args);
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

   my $context = $self->context;

   if (! defined($script)) {
      $Log->error("run: you must provide a script to run");
      return;
   }

   if (! -f $script) {
      $Log->error("run: script [$script] is not a file");
      return;
   }

   open(my $in, '<', $script)
      or die("[FATAL] core::meby::run_script: can't open file [$script]: $!\n");
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

   my $context = $self->context;

   my $commands = $self->ps_get_commands;
   for my $command (@$commands) {
      if ($args[0] eq $command) {
         return $self->run_command(@args);
      }
   }

   my $available = $context->get_available_bricks or return;
   if (defined($available)) {
      for my $brick (keys %$available) {
         if ($args[0] eq $brick) {
            print "DEBUG match[$brick]\n";
            #$self->ps_update_prompt("[$brick]> ");
            #$self->ps_update_prompt;
            #return $self->run_command(@args);
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

   my $context = $self->context;

   my @dirs = ();
   eval {
      @dirs = io($dir)->all_dirs;
   };
   if ($@) {
      chomp($@);
      $Log->error("$dir: dirs: $@");
      return [], [];
   }

   my @files = ();
   eval {
      @files = io($dir)->all_files;
   };
   if ($@) {
      chomp($@);
      $Log->error("$dir: files: $@");
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

   #print "[DEBUG] word[$word] line[$line] start[$start]\n";

   my $context = $self->context;

   my $available = $context->get_available_bricks or return;
   if (! defined($available)) {
      $Log->warning("can't fetch available Bricks");
      return ();
   }

   my @comp = ();
   for my $a (keys %$available) {
      #print "[$a] [$word]\n";
      push @comp, $a if $a =~ /^$word/;
   }

   return @comp;
}

sub comp_set {
   return shift->comp_run(@_);
}

sub comp_load {
   return shift->comp_run(@_);
}

sub comp_doc {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   #print "[DEBUG] word[$word] line[$line] start[$start]\n";

   my %comp = ();
   for my $inc (@INC) {
      if (! -d $inc) {
         next;
      }
      #print "[DEBUG] inc[$inc]\n";
      my $r = opendir(my $dir, $inc);
      if (! defined($r)) {
         $Log->error("comp_doc: opendir: $dir: $!");
         next;
      }

      my @dirs = readdir($dir);
      my @comp = grep(/^$word/, @dirs);
      #print "@comp\n";
      for my $c (@comp) {
         $comp{$c}++;
      }
   }

   return keys %comp;
}

# Default to check for global completion value
sub catch_comp {
   my $self = shift;
   my ($word, $line, $start) = @_;

   #print "[DEBUG] word[$word] line[$line] start[$start]\n";

   my $dir = '.';
   if (defined($line)) {
      my $home = $self->path_home;
      $line =~ s/^~/$home/;
      if ($line =~ /^(.*)\/.*$/) {
         $dir = $1 || '/';
      }
   }

   #print "\nDIR[$dir]\n";

   my ($dirs, $files) = $self->_ioa_dirsfiles($dir, $line);

   return @$dirs, @$files;
}

#
# DESTROY
#
sub DESTROY {
   my $self = shift;

   if (defined($self->term) && $self->term->can('WriteHistory')) {
      if (defined(my $history = $self->meby_history)) {
         $self->term->WriteHistory($history)
            or die("[FATAL] core::meby::DESTROY: ".
                   "can't write history file [$history]: $!\n");
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabricky::Brick::Core::Meby - the Metabricky shell

=head1 SYNOPSIS

   use Metabricky::Log::Console;
   use Metabricky::Brick::Core::Meby;

   $Metabricky::Brick::Core::Meby::Log = Metabricky::Log::Console->new(
      level => 3,
   );

   my $meby = Metabricky::Brick::Core::Meby->new;
   $meby->cmdloop;

=head1 DESCRIPTION

Interactive use of the Metabricky shell.

=head2 GLOBAL VARIABLES

=head3 B<$Metabricky::Brick::Core::Meby::Log>

Specify a log object. Must be an object inherited from L<Metabricky::Log>.

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
