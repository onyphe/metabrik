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
      },
      require_modules => {
         'Daemon::Daemonize' => [ ],
         'POSIX' => [ qw(:sys_wait_h) ],
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

   if ($process =~ /^\d+$/) {
      kill('TERM', $process);
      my $kid = waitpid(-1, POSIX::WNOHANG());
   }
   else {
      my $list = $self->get_process_info($process) or return;
      for my $this (@$list) {
         kill('TERM', $this->{PID});
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

   my $r;
   # Daemonize the given subroutine
   if (defined($sub)) {
      $r = Daemon::Daemonize->daemonize(
         %opts,
         run => $sub,
      );
   }
   # Or myself
   else {
      $r = Daemon::Daemonize->daemonize(
         %opts,
      );
   }

   #$self->log->info("daemonize: returned [$r]");

   return 1;
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
