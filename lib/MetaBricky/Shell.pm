#
# $Id$
#
package MetaBricky::Shell;
use strict;
use warnings;

use base qw(Term::Shell Class::Gomor::Hash);

our @AS = qw(
   path_home
   path_cwd
   prompt
   mebyrc
   mebyrc_history
   ps1
   title
   context
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Cwd;
use File::HomeDir qw(home);
use IO::All;
use Module::Reload;
use IPC::Run;

use MetaBricky;
use MetaBricky::Context;
use MetaBricky::Ext::Utils qw(peu_convert_path);

# Exists because we cannot give an argument to Term::Shell::new()
# Or I didn't found how to do it.
our $Log;

# Exists to avoid compile-time errors.
# It is only used by MetaBricky::Context.
my $global;

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
      die("[-] FATAL: MetaBricky::Shell::init: you must create a `Log' object\n");
   }

   my $context = MetaBricky::Context->new(
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

   $context->global_update_available_bricks
      or $Log->fatal("init: global_update_available_bricks");

   my $available = $context->global_get('available')
      or $Log->fatal("init: unable to get available bricks");
   for my $a (keys %$available) {
      $self->add_handlers("run_$a");
   }

   #{
      #no strict 'refs';
      #use Data::Dumper;
      #print Dumper(\%{"MetaBricky::Shell::"})."\n";
      #my $commands = $self->ps_get_commands;
      #for my $command (@$commands) {
         #print "** adding command [$command]\n";
         #${"MetaBricky::Shell::"}{"run_$command"} = 1;
      #}
      #print Dumper(\%{"MetaBricky::Shell::"})."\n";
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
# MetaBricky::Shell stuff
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

   my $commands = $context->global_get('commands');
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
      return $_ = $MetaBricky::VERSION;
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

   my $newline = $context->global_get('newline');
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

# Just an alias
sub run_load {
   my $self = shift;
   my ($brick) = @_;

   my $r = $self->cmd("run global load $brick");
   if ($r) {
      $Log->verbose("Brick [$brick] loaded");
   }

   return $r;
}

sub run_show {
   my $self = shift;

   my $context = $self->context;

   $context->call(sub {
      my $__lp_available = $global->available;
      my $__lp_loaded = $global->loaded;

      print "Available bricks:\n";

      my @__lp_loaded = ();
      my @__lp_notloaded = ();

      my $__lp_total = 0;
      for my $k (sort { $a cmp $b } keys %$__lp_available) {
         #print "   $k";
         #print (exists $__lp_loaded->{$k} ? " [LOADED]\n" : "\n");
         exists($__lp_loaded->{$k}) ? push @__lp_loaded, $k : push @__lp_notloaded, $k;
         $__lp_total++;
      }

      my $__lp_count = 0;
      print "   Loaded:\n";
      for my $loaded (@__lp_loaded) {
         print "      $loaded\n";
         $__lp_count++;
      }
      print "   Count: $__lp_count\n";

      $__lp_count = 0;
      print "   Not loaded:\n";
      for my $notloaded (@__lp_notloaded) {
         print "      $notloaded\n";
         $__lp_count++;
      }
      print "   Count: $__lp_count\n";

      print "Total: $__lp_total\n";

      return 1;
   }) or return;

   return 1;
}

sub run_set {
   my $self = shift;
   my ($brick, $k, $v) = @_;

   my $context = $self->context;

   # set is called, we display everything
   if (! defined($brick)) {
      my $r = $context->call(sub {
         my $__lp_set = $global->set;
         my $__lp_count = 0;

         print "Set variable(s):\n";

         for my $brick (sort { $a cmp $b } keys %$__lp_set) {
            for my $k (sort { $a cmp $b } keys %{$__lp_set->{$brick}}) {
               print "   $brick $k ".$__lp_set->{$brick}->{$k}."\n";
               $__lp_count++;
            }
         }

         print "Total: $__lp_count\n";
      });
      if (! defined($r)) {
         return;
      }

      return 1;
   }
   # set is called with a brick, we show its attributes
   elsif (! defined($k)) {
      my $available = $context->global_get('available') or return;

      if (! exists($available->{$brick})) {
         $Log->error("Brick [$brick] does not exist");
         return;
      }

      my $r = $context->call(sub {
         my %args = @_;

         my $__lp_set = $global->set;
         my $__lp_count = 0;

         my $__lp_brick = $__lp_set->{$args{brick}};

         print "Set variable(s):\n";

         for my $k (sort { $a cmp $b } keys %$__lp_brick) {
            print "   $args{brick} $k ".$__lp_brick->{$k}."\n";
            $__lp_count++;
         }

         print "Total: $__lp_count\n";
      }, brick => $brick);
      if (! defined($r)) {
         return;
      }

      return 1;
   }

   my $r = $context->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};

      if (! exists($global->loaded->{$__lp_brick})) {
         die("Brick [$__lp_brick] not loaded or does not exist\n");
      }
   }, brick => $brick);
   if (! defined($r)) {
      $Log->error("run_set2");
      return;
   }

   $r = $context->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_key = $args{key};
      my $__lp_val = $args{val};

      #$global->loaded->{$__lp_brick}->init; # No init when just setting an attribute
      $global->loaded->{$__lp_brick}->$__lp_key($__lp_val);
      $global->set->{$__lp_brick}->{$__lp_key} = $__lp_val;
   }, brick => $brick, key => $k, val => $v);
   if (! defined($r)) {
      $Log->error("run_set3");
      return;
   }

   return 1;
}

sub run_run {
   my $self = shift;
   my ($brick, $command, @args) = @_;

   my $context = $self->context;

   $context->call(sub {
      my %args = @_;

      my $__lp_brick = $args{brick};
      my $__lp_command = $args{command};
      my @__lp_args = @{$args{args}};

      if (! defined($__lp_brick)) {
         die("no Brick specified\n");
      }
      if (! defined($__lp_command)) {
         die("no Brick command specified\n");
      }

      my $__lp_run = $global->loaded->{$__lp_brick};
      if (! defined($__lp_run)) {
         die("Brick [$__lp_brick] not loaded\n");
      }

      $__lp_run->init; # Will init() only if not already done

      if (! $__lp_run->can("$__lp_command")) {
         die("no command [$__lp_command] defined for brick [$__lp_brick]\n");
      }

      $_ = $__lp_run->$__lp_command(@__lp_args);

      $global->shell->run_title("$_");

      return $_;
   }, brick => $brick, command => $command, args => \@args)
      or return;

   return 1;
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
      or die("[-] FATAL: MetaBricky::Shell::run_script: can't open file [$script]: $!\n");
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
execute meby commands as contained in the specified script
END
}

sub smry_script {
   "execute meby commands as contained in the specified script"
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

   my $available = $context->global_get('available') or return;
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

# XXX: move in MetaBricky::Ext
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

   my $available = $context->global_get('available');
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
            or die("[-] FATAL: MetaBricky::Shell::DESTROY: ".
                   "can't write history file [$history]: $!\n");
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

MetaBricky::Shell - The MetaBricky Shell

=head1 SYNOPSIS

   use MetaBricky::Shell;
   use MetaBricky::Log::Console;

   $MetaBricky::Shell::Log = MetaBricky::Log::Console->new(
      level => 3,
   );

   my $shell = MetaBricky::Shell->new;
   $shell->cmdloop;

=head1 DESCRIPTION

Interactive use of the MetaBricky Shell.

=head2 GLOBAL VARIABLES

=head3 B<$MetaBricky::Shell::Log>

Specify a log object. Must be an object inherited from L<MetaBricky::Log>.

=head2 COMMANDS

=head3 B<new>

=head1 SEE ALSO

L<MetaBricky::Log>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
