#
# $Id$
#
# system::process Brik
#
package Metabrik::System::Process;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable system process) ],
      attributes => {
         datadir => [ qw(datadir) ],
         force_kill => [ qw(0|1) ],
         close_output_on_daemonize => [ qw(0|1) ],
      },
      attributes_default => {
         force_kill => 0,
         close_output_on_daemonize => 1,
      },
      commands => {
         list => [ ],
         is_running => [ qw(process) ],
         get_process_info => [ qw(process) ],
         kill => [ qw(process|pid) ],
         daemonize => [ qw($sub) ],
         list_daemons => [ ],
         get_latest_daemon_id => [ ],
         kill_from_pidfile => [ qw(pidfile) ],
         is_running_from_pidfile => [ qw(pidfile) ],
      },
      require_modules => {
         'Daemon::Daemonize' => [ ],
         'POSIX' => [ qw(:sys_wait_h) ],
         'Metabrik::File::Find' => [ ],
      },
      require_binaries => {
         'ps', => [ ],
      },
   };
}

sub list {
   my $self = shift;

   my $res = $self->capture("ps awuxw") or return;

   my @a = ();
   my $first = shift @$res;
   my $header = [ split(/\s+/, $first) ];
   my $count = scalar(@$header) - 1;
   for my $this (@$res) {
      my @toks = split(/\s+/, $this);
      my $h = {};
      for my $n (0..$count) {
         $h->{$header->[$n]} = $toks[$n];
      }
      my $ntoks = scalar(@toks) - 1;
      if ($ntoks > $count) {
         for my $n (($count+1)..$ntoks) {
            $h->{$header->[-1]} .= ' '.$toks[$n];
         }
      }
      push @a, $h;
   }

   return \@a;
}

sub is_running {
   my $self = shift;
   my ($process) = @_;

   if (! defined($process)) {
      return $self->log->error($self->brik_help_run('is_running'));
   }

   my $list = $self->list or return;
   for my $this (@$list) {
      my $command = $this->{COMMAND};
      my @toks = split(/\s+/, $command);
      $toks[0] =~ s/^.*\/(.*?)$/$1/;
      if ($toks[0] eq $process) {
         return 1;
      }
   }

   return 0;
}

sub get_process_info {
   my $self = shift;
   my ($process) = @_;

   if (! defined($process)) {
      return $self->log->error($self->brik_help_run('is_running'));
   }

   my @results = ();
   my $list = $self->list or return;
   for my $this (@$list) {
      my $command = $this->{COMMAND};
      my @toks = split(/\s+/, $command);
      $toks[0] =~ s/^.*\/(.*?)$/$1/;
      if ($toks[0] eq $process) {
         push @results, $this;
      }
   }

   return \@results;
}

sub kill {
   my $self = shift;
   my ($process) = @_;

   if (! defined($process)) {
      return $self->log->error($self->brik_help_run('kill'));
   }

   my $signal = $self->force_kill ? 'KILL' : 'TERM';

   if ($process =~ /^\d+$/) {
      kill($signal, $process);
      my $kid = waitpid(-1, POSIX::WNOHANG());
   }
   else {
      my $list = $self->get_process_info($process) or return;
      for my $this (@$list) {
         kill($signal, $this->{PID});
         my $kid = waitpid(-1, POSIX::WNOHANG());
      }
   }

   return 1;
}

sub daemonize {
   my $self = shift;
   my ($sub) = @_;

   my %opts = (
      close => $self->close_output_on_daemonize,
   );

   my $new_pid;
   my $pidfile;
   # Daemonize the given subroutine
   if (defined($sub)) {
      my $id = $self->get_latest_daemon_id;
      defined($id) ? $id++ : ($id = 1);
      $pidfile = $self->datadir."/daemonpid.$id";

      my $r = Daemon::Daemonize->daemonize(
         %opts,
         run => $sub,
      );

      # Waiting for new pidfile to be created, but no more than 100_000 loops.
      #my $count = 100_000;
      #while (! ($new_pid = Daemon::Daemonize->read_pidfile($pidfile))) {
         #last if ++$count == 100_00;
      #}
      my $written = 0;
      my $count = 100_000;
      my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
      while (1) {
         my $list = $sp->get_process_info("arpspoof") or return;
         for (@$list) {
            # First process if the good one
            if (exists($_->{PID})) {
               $new_pid = $_->{PID};
               Daemon::Daemonize->write_pidfile($pidfile, $new_pid);
               $written++;
               last;
            }
         }
         last if $written;
         last if ++$count == 100_000;
      }
   }
   # Or myself. But no handling of pidfile there.
   else {
      Daemon::Daemonize->daemonize(
         %opts,
      );
   }

   $self->log->verbose("daemonize: new daemon with pid [$new_pid] started");

   return defined($new_pid) ? $pidfile : 1;
}

sub list_daemons {
   my $self = shift;

   my $datadir = $self->datadir;

   my $ff = Metabrik::File::Find->new_from_brik_init($self) or return;
   my $list = $ff->files($datadir, 'daemonpid\.\d+');

   my %daemons = ();
   for (@$list) {
      my ($id) = $_ =~ m{\.(\d+)$};
      my $pid = Daemon::Daemonize->read_pidfile($_) or next;
      $daemons{$id} = { file => $_, pid => $pid };
   }

   return \%daemons;
}

sub get_latest_daemon_id {
   my $self = shift;

   my $list = $self->list_daemons or return;

   my $id = 0;
   for (keys %$list) {
      if ($_ > $id) {
         $id = $_;
      }
   }

   return $id;
}

sub kill_from_pidfile {
   my $self = shift;
   my ($pidfile) = @_;

   if (! defined($pidfile)) {
      return $self->log->error($self->brik_help_run('kill_from_pidfile'));
   }

   if (my $pid = Daemon::Daemonize->check_pidfile($pidfile)) {
      $self->log->verbose("kill_from_pidfile: file[$pidfile] and pid[$pid]");
      $self->kill($pid);
      Daemon::Daemonize->delete_pidfile($pidfile);
   }

   return 1;
}

sub is_running_from_pidfile {
   my $self = shift;
   my ($pidfile) = @_;

   if (! defined($pidfile)) {
      return $self->log->error($self->brik_help_run('is_running_from_pidfile'));
   }

   if (my $pid = Daemon::Daemonize->check_pidfile($pidfile)) {
      return 1;
   }

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::System::Process - system::process Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
