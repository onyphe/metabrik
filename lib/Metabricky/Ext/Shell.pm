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
   newline
   commands
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

use vars qw{$AUTOLOAD};

sub AUTOLOAD {
   my $self = shift;

   $self->log->debug("autoload[$AUTOLOAD]");
   $self->log->debug("self[$self]");

   $self->ps_update_prompt('xxx $AUTOLOAD ');
   #$self->ps1('$AUTOLOAD ');
   $self->ps_update_prompt;

   return 1;
}

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
         or $self->log->fatal("ext::shell: init: can't open rc file [$rc]: $!");
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
            or $self->log->fatal("ext::shell: init: can't read history file [$history]: $!");
      }
   }

   # XXX: not used now
   #my $available = $context->available
      #or $self->log->fatal("ext::shell: init: unable to get available bricks");
   #for my $a (keys %$available) {
      #$self->add_handlers("run_$a");
   #}

   #{
      #no strict 'refs';
      #use Data::Dumper;
      #print Dumper(\%{"Metabricky::Brick::Shell::Meby::"})."\n";
      #my $commands = $self->ps_get_commands;
      #for my $command (@$commands) {
         #print "** adding command [$command]\n";
         #${"Metabricky::Brick::Shell::Meby::"}{"run_$command"} = 1;
      #}
      #print Dumper(\%{"Metabricky::Brick::Shell::Meby::"})."\n";
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
         $self->log->debug("ext::shell: ps_lookup_var: unable to lookup variable [$var]");
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
               $self->log->debug("ext::shell: ps_lookup_vars_in_line: unable to lookup variable [$a]");
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

   my $context = $Bricks->{'core::context'};

   my $commands = $context->get('shell::meby', 'commands');
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
         $self->log->error("ext::shell: write_history: unable to write history file");
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

# For commands that do not need a terminal
sub run_command {
   my $self = shift;
   my (@args) = @_;

   my $context = $Bricks->{'core::context'};

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

   my $context = $Bricks->{'core::context'};

   if ($^O =~ /win32/i) {
      return system(@args);
   }
   else {
      eval("use Proc::Simple");
      if ($@) {
         chomp($@);
         $self->log->fatal("ext::shell: can't load Proc::Simple module: $@");
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

   my $context = $Bricks->{'core::context'};

   if (! defined($file)) {
      $self->log->error("ext::shell: save: pass \$data and \$file parameters");
      return;
   }

   $data = $self->ps_lookup_var($data);

   my $r = open(my $out, '>', $file);
   if (!defined($r)) {
      $self->log->error("ext::shell: save: unable to open file [$file] for writing: $!");
      return;
   }
   print $out $data;
   close($out);

   return 1;
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   my $context = $Bricks->{'core::context'};

   if (defined($dir)) {
      if (! -d $dir) {
         $self->log->error("ext::shell: cd: $dir: can't cd to this");
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

   my $context = $Bricks->{'core::context'};

   if (! defined($args[0])) {
      $self->log->error("ext::shell: doc: you have to provide a module as an argument");
      return;
   }

   system('perldoc', @args);

   return 1;
}

sub run_sub {
   my $self = shift;
   my (@args) = @_;

   my $context = $Bricks->{'core::context'};

   if (! defined($args[0])) {
      $self->log->error("ext::shell: sub: you have to provide a function as an argument");
      return;
   }

   system('perldoc', '-f', @args);

   return 1;
}

sub run_src {
   my $self = shift;
   my (@args) = @_;

   my $context = $Bricks->{'core::context'};

   if (! defined($args[0])) {
      $self->log->error("ext::shell: src: you have to provide a module as an argument");
      return;
   }

   system('perldoc', '-m', @args);

   return 1;
}

sub run_faq {
   my $self = shift;
   my (@args) = @_;

   my $context = $Bricks->{'core::context'};

   if (! defined($args[0])) {
      $self->log->error("ext::shell: faq: you have to provide a question as an argument");
      return;
   }

   system('perldoc', '-q', @args);

   return 1;
}

sub run_pl {
   my $self = shift;
   my (@args) = @_;

   my $context = $Bricks->{'core::context'};

   my $line = $self->line;
   #print "[DEBUG] [$line]\n";
   $line =~ s/^pl\s+//;

   if ($self->newline && $line =~ /^\s*print/) {
      $line .= ';print "\n";';
   }

   my $r = $context->do($line, $self->echo);
   if (! defined($r)) {
      $self->log->error("ext::shell: pl: unable to execute Code [$line]");
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
      $self->log->info("ext::shell: reload: some modules were reloaded");
   }

   return 1;
}

sub run_load {
   my $self = shift;
   my ($brick) = @_;

   my $context = $Bricks->{'core::context'};

   my $r = $context->load($brick) or return;
   if ($r) {
      $self->log->verbose("ext::shell: load: Brick [$brick] loaded");
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
         $self->log->error("ext::shell: set: Brick [$brick] does not exist");
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
         $self->log->error("ext::shell: set: Brick [$brick] does not exist");
         return;
      }

      if (! exists($attributes->{$brick}->{$attribute})) {
         $self->log->error("ext::shell: set: Attribute [$attribute] does not exist for Brick [$brick]");
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
         $self->log->error("ext::shell: set: unable to set Brick [$brick] Attribute [$attribute] to Value [$value]");
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
      $self->log->error("ext::shell: run: unable to execute Command [$command] for Brick [$brick]");
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
      $self->log->error("ext::shell: script: you must provide a script to run");
      return;
   }

   if (! -f $script) {
      $self->log->error("ext::shell: script: script [$script] is not a file");
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

   my $commands = $self->ps_get_commands;
   for my $command (@$commands) {
      if ($args[0] eq $command) {
         $self->log->debug("catch_run: command [$command]");
         return $self->run_command(@args);
      }
   }

   my $available = $context->available or return;
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

   my @dirs = ();
   eval {
      @dirs = io($dir)->all_dirs;
   };
   if ($@) {
      chomp($@);
      $self->log->error("ext::shell: $dir: dirs: $@");
      return [], [];
   }

   my @files = ();
   eval {
      @files = io($dir)->all_files;
   };
   if ($@) {
      chomp($@);
      $self->log->error("ext::shell: $dir: files: $@");
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

   my $context = $Bricks->{'core::context'};

   my $available = $context->available or return;
   if (! defined($available)) {
      $self->log->warning("ext::shell: comp_run: can't fetch available Bricks");
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

   #print "[DEBUG] word[$word] line[$line] start[$start]\n";

   my %comp = ();
   for my $inc (@INC) {
      if (! -d $inc) {
         next;
      }
      #print "[DEBUG] inc[$inc]\n";
      my $r = opendir(my $dir, $inc);
      if (! defined($r)) {
         $self->log->error("ext::shell: comp_doc: opendir: $dir: $!");
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
