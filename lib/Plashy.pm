#
# $Id$
#
package Plashy;
use strict;
use warnings;

our $VERSION = '0.10';

use base qw(Term::Shell);

use Plashy::Log;

use Cwd;
use Data::Dumper;
use IO::All;
use Lexical::Persistence;
use Module::Reload;
use File::HomeDir qw(home);

# Note: it is only accessible within Lexical::Persistence scope.
# It is here to avoid compilation time errors against $global variable scope.
my $global = {
};

sub init {
   my $self = shift;

   $|++;

   my $log = Plashy::Log->new;
   $self->{plashy}->{log} = $log;

   my $lp = Lexical::Persistence->new;
   $self->{plashy}->{lp} = $lp;

   $lp->do('use strict');
   $lp->do('use warnings');
   $lp->do('use Data::Dumper');
   $lp->do('use Plashy::Plugin::Global');

   eval {
      $lp->call(sub {
         my %args = @_;
         my $log = $args{log};
         my $plashy = $args{plashy};
         my $global = Plashy::Plugin::Global->new(
            log => $log,
            plashy => $plashy,
         );
         $global->init;
         #$global->input(\*STDIN);
         #$global->output(\*STDOUT);
      }, log => $log, plashy => $self);
   };
   if ($@) {
      $log->fatal("can't initialize global plugin: $@");
   }

   my $cwd = getcwd();
   $cwd =~ s/\\/\//g; # Converts Windows path
   $self->{plashy}->{cwd} = $cwd;
   my $home = home();
   $home =~ s/\\/\//g; # Converts Windows path
   $self->{plashy}->{home} = $home;
   my $rc = $self->{plashy}->{rc} = $self->{plashy}->{home}."/.plashyrc";
   my $history = $self->{plashy}->{history} = $self->{plashy}->{home}."/.plashy_history";

   $self->_update_prompt;
   $self->_set_signals;

   if (-f $rc) {
      open(my $in, '<', $rc) or $log->fatal("can't open rc file [$rc]: $!");
      while (defined(my $line = <$in>)) {
         next if ($line =~ /^\s*#/);  # Skip comments
         chomp($line);
         $self->cmd($line);
      }
      close($in);
   }

   if ($self->{term}->can('ReadHistory')) {
      if (-f $history) {
         $self->{term}->ReadHistory($history)
            or $log->fatal("can't read history file [$history]: $!");
      }
   }

   return $self;
}

sub prompt_str {
   my $self = shift;

   return $self->{plashy}->{ps1};
}

sub cmdloop {
   my $self = shift;

   $self->{stop} = 0;
   $self->preloop;

   my $buf = '';
   while (defined (my $line = $self->readline($self->prompt_str))) {
      $buf .= $line;

      if ($line =~ /[;{]\s*$/) {
         $self->_update_prompt('> ');
         next;
      }

      $self->cmd($buf);
      $buf = '';
      $self->_update_prompt;

      last if $self->{stop};
   }

   return $self->postloop;
}

sub _update_prompt {
   my $self = shift;
   my ($str) = @_;

   if (! defined($str)) {
      my $cwd = $self->{plashy}->{cwd};
      my $home = $self->{plashy}->{home};
      $cwd =~ s/$home/~/;

      my $ps1 = "plashy $cwd> ";
      if ($< == 0) {
         $ps1 =~ s/> /# /;
      }

      $self->{plashy}->{ps1} = $ps1;
   }
   else {
      $self->{plashy}->{ps1} = $str;
   }

   return 1;
}

sub _set_signals {
   my $self = shift;

   #$SIG{INT} = 'IGNORE';
   #$SIG{INT} = sub { return 1; };
   $SIG{INT} = sub { $self->stoploop; $self->cmdloop };

   return 1;
}

#
# Classic shell stuff
#
sub run_sh {
   my $self = shift;
   my ($cmd, @args) = @_;

   #print "[DEBUG] cmd[$cmd] args[@args]\n";
   #system($cmd, @args);
   my $out = `$cmd @args`;
   $self->{plashy}->{lp}->call(sub {
      my %h = @_;
      $_ = $h{out};
   }, out => $out);

   print $out;

   return 1;
}

my $jobs = {};

sub run_system {
   my $self = shift;
   my ($cmd, @args) = @_;

   if ($^O =~ /win32/i) {
      return $_ = system($cmd, @args);
   }
   else {
      eval("use Proc::Simple");
      if ($@) {
         $self->global->{log}->fatal("can't load Proc::Simple module: $@");
         return;
      }

      $SIG{STOP} = sub {
         print "DEBUG SIGSTOP\n";
         $jobs->{current}->kill("SIGSTOP");
      };
      $SIG{CONT} = sub {
         print "DEBUG SIGCONT\n";
         $jobs->{current}->kill("SIGCONT");
      };

      my $bg = (defined($args[-1]) && $args[-1] eq '&') || 0;
      if ($bg) {
         pop @args;
      }

      my $proc = Proc::Simple->new;
      $proc->start($cmd, @args);
      $jobs->{current} = $proc;
      if (! $bg) {
         my $status = $proc->wait; # Blocking until process exists
         return $_ = $status;
      }

      return $_ = $proc;
   }

   return;
}

sub run_w {
   return shift->run_sh('w');
}

sub run_l {
   my $self = shift;

   if ($^O =~ /win32/i) {
      return $self->run_sh('dir', @_);
   }
   else {
      return $self->run_sh('ls', '-lF', @_);
   }
}

sub run_li {
   my $self = shift;
   my (@args) = @_;

   my $cwd = $self->{plashy}->{cwd};

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

sub run_vi {
   return shift->run_system($ENV{EDITOR}, @_);
}

sub run_history {
   my $self = shift;
   my ($c) = @_;

   my @history = $self->{term}->GetHistory;
   if (defined($c)) {
      return $self->cmd($history[$c]);
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

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;


   if (defined($dir)) {
      if (! -d $dir) {
         $self->{plashy}->{log}->error("cd: $dir: can't cd to this");
         return;
      }
      chdir($dir);
      $self->{plashy}->{cwd} = getcwd();
   }
   else {
      chdir($self->{plashy}->{home});
      $self->{plashy}->{cwd} = $self->{plashy}->{home};
   }

   $self->_update_prompt;

   return 1;
}

sub run_pwd {
   my $self = shift;

   print $self->{plashy}->{cwd}."\n";

   return 1;
}

#
# Specific shell stuff
#
sub run_doc {
   my $self = shift;
   my (@args) = @_;

   if (! defined($args[0])) {
      $self->{plashy}->{log}->error("You have to provide a module as an argument");
      return;
   }

   system('perldoc', @args);

   return 1;
}

sub run_sub {
   my $self = shift;
   my (@args) = @_;

   if (! defined($args[0])) {
      $self->{plashy}->{log}->error("You have to provide a function as an argument");
      return;
   }

   system('perldoc', '-f', @args);

   return 1;
}

sub run_src {
   my $self = shift;
   my (@args) = @_;

   if (! defined($args[0])) {
      $self->{plashy}->{log}->error("You have to provide a module as an argument");
      return;
   }

   system('perldoc', '-m', @args);

   return 1;
}

sub run_faq {
   my $self = shift;
   my (@args) = @_;

   if (! defined($args[0])) {
      $self->{plashy}->{log}->error("You have to provide a question as an argument");
      return;
   }

   system('perldoc', '-q', @args);

   return 1;
}

sub run_readline {
   my $self = shift;

   my $lp = $self->{plashy}->{lp};

   my $line;
   eval {
      $lp->call(sub {
         my %args = @_;

         my $line = $args{line};

         my $input = $global->input;
         #print "DEBUG input[$input]\n";

         my $read = <$input>;
         #print "DEBUG read[$read]\n";
         $$line = $read;
      }, line => \$line);
   };
   if ($@) {
      $self->{plashy}->{log}->error("readline::call: $@");
   }

   #print "DEBUG line[$line]\n";

   return $_ = $line;
}

sub run_readall {
   my $self = shift;

   my $lp = $self->{plashy}->{lp};

   my $line;
   eval {
      $lp->call(sub {
         my %args = @_;

         my $line = $args{line};

         my $input = $global->input;
         #print "DEBUG input[$input]\n";

         my @read = <$input>;
         #print "DEBUG read[$read]\n";
         $$line = [ @read ];
      }, line => \$line);
   };
   if ($@) {
      $self->{plashy}->{log}->error("readall::call: $@");
   }

   #print "DEBUG line[$line]\n";

   return $_ = $line;
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
         $self->{plashy}->{log}->error("comp_doc: opendir: $dir: $!");
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

sub run_pl {
   my $self = shift;
   my (@args) = @_;

   my $line = $self->line;
   #print "[DEBUG] [$line]\n";
   $line =~ s/^pl\s+//;

   use Data::Dump;

   eval {
      Data::Dump::dump($self->{plashy}->{lp}->do($line));
   };
   if ($@) {
      $self->{plashy}->{log}->error($@);
      return;
   }
   else {
      print "\n";
   }

   return 1;
}

# Default to execute Perl commands
sub catch_run {
   my $self = shift;
   my (@args) = @_;

   #print "[DEBUG] catch_run[@args]\n";

   return $self->run_pl(@_);
}

sub _ioa_dirsfiles {
   my $self = shift;
   my ($dir, $grep) = @_;

   #print "\nDIR[$dir]\n";

   my @dirs = ();
   eval {
      @dirs = io($dir)->all_dirs;
   };
   if ($@) {
      $self->{plashy}->{log}->error("$dir: dirs: $!");
      return [], [];
   }

   my @files = ();
   eval {
      @files = io($dir)->all_files;
   };
   if ($@) {
      $self->{plashy}->{log}->error("$dir: files: $!");
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

# Default to check for global completion value
sub catch_comp {
   my $self = shift;
   my ($word, $line, $start) = @_;

   #print "[DEBUG] word[$word] line[$line] start[$start]\n";

   my $dir = '.';
   if (defined($line)) {
      my $home = $self->{plashy}->{home};
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
# Plashy specifics
#
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
      $self->{plashy}->{log}->info("Some modules were reloaded");
   }

   return 1;
}

# Just an alias
sub run_load {
   my $self = shift;
   my ($plugin) = @_;

   return $self->cmd("run global load $plugin");
}

sub run_show {
   my $self = shift;

   my $lp = $self->{plashy}->{lp};

   eval {
      $lp->call(sub {
         my $loaded = $global->loaded;
         my $count = 0;
         print "Loaded plugin(s):\n";
         for my $k (sort { $a cmp $b } keys %$loaded) {
            print "   $k\n";
            $count++;
         }
         print "Total: $count\n";
      });
   };
   if ($@) {
      $self->{plashy}->{log}->error("show::call: $@");
      return;
   }

   return 1;
}

sub run_set {
   my $self = shift;
   my ($plugin, $k, $v) = @_;

   my $lp = $self->{plashy}->{lp};

   if (! defined($plugin)) {
      eval {
         $lp->call(sub {
            my $set = $global->set;
            my $count = 0;
            print "Set variable(s):\n";
            for my $plugin (sort { $a cmp $b } keys %$set) {
               for my $k (sort { $a cmp $b } keys %{$set->{$plugin}}) {
                  print "   $plugin $k ".$set->{$plugin}->{$k}."\n";
                  $count++;
               }
            }
            print "Total: $count\n";
         });
      };
      if ($@) {
         $self->{plashy}->{log}->error("set::call: $@");
         return;
      }

      return 1;
   }

   eval {
      $lp->call(sub {
         my %args = @_;
         my $plugin = $args{plugin};
         if (! exists($global->loaded->{$plugin})) {
            die("plugin [$plugin] not loaded or does not exist\n");
         }
      }, plugin => $plugin);
   };
   if ($@) {
      $self->{plashy}->{log}->error("set::call: $@");
      return;
   }

   eval {
      $lp->call(sub {
         my %args = @_;
         my $plugin = $args{plugin};
         my $key = $args{key};
         my $val = $args{val};
         #$global->loaded->{$plugin}->init; # No init when just setting an attribute
         $global->loaded->{$plugin}->$key($val);
         $global->set->{$plugin}->{$key} = $val;
      }, plugin => $plugin, key => $k, val => $v);
   };
   if ($@) {
      $self->{plashy}->{log}->error("set::call: $@");
      return;
   }

   return 1;
}

sub run_run {
   my $self = shift;
   my ($plugin, $method, @args) = @_;

   my $lp = $self->{plashy}->{lp};

   eval {
      $lp->call(sub {
         my %args = @_;
         my $method = $args{method};
         my $plugin = $args{plugin};
         my @args = @{$args{args}};
         my $run = $global->loaded->{$plugin};
         if (! defined($run)) {
            die("plugin [$plugin] not loaded\n");
         }
         $run->init; # Will init() only if not already done
         if (! $run->can("$method")) {
            die("no method [$method] defined for plugin [$plugin]\n");
         }
         $_ = $run->$method(@args);
      }, plugin => $plugin, method => $method, args => \@args);
   };
   if ($@) {
      $self->{plashy}->{log}->error("run::call: $@");
      return;
   }

   return 1;
}

sub run_script {
   my $self = shift;
   my ($script) = @_;

   if (! defined($script)) {
      $self->{plashy}->{log}->error("run::script: you must provide a script to run");
      return;
   }

   if (! -f $script) {
      $self->{plashy}->{log}->error("run::script: script [$script] is not a file");
      return;
   }

   open(my $in, '<', $script) or die("can't open file [$script]: $!");
   while (defined(my $line = <$in>)) {
      next if ($line =~ /^\s*#/);  # Skip comments
      chomp($line);
      $self->cmd($line);
   }
   close($in);

   return 1;
}

sub DESTROY {
   my $self = shift;

   if ($self->{term}->can('WriteHistory')) {
      my $history = $self->{plashy}->{home}."/.plashy_history";
      $self->{term}->WriteHistory($history)
         or $self->{plashy}->{log}->fatal("can't write history file [$history]: $!");
   }

   return 1;
}

1;

__END__
