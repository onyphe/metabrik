#
# $Id$
#
# network::wlan Brik
#
package Metabrik::Network::Wlan;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable wifi wlan wireless monitor) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         monitor => [ qw(device) ],
         essid => [ qw(essid) ],
         key => [ qw(key) ],
         bitrate => [ qw(bitrate_mb|54MB|130MB) ],
         _monitor_mode_started => [ ],
      },
      attributes_default => {
         device => 'wlan0',
         monitor => 'mon0',
      },
      commands => {
         scan => [ qw(device|OPTIONAL) ],
         set_bitrate => [ qw(bitrate|OPTIONAL device|OPTIONAL) ],
         set_wepkey => [ qw(key|OPTIONAL device|OPTIONAL) ],
         connect => [ qw(device|OPTIONAL essid|OPTIONAL) ],
         start_monitor_mode => [ ],
         stop_monitor_mode => [ ],
      },
      require_binaries => {
         'sudo', => [ ],
         'iwlist', => [ ],
         'iwconfig', => [ ],
      },
   };
}

sub scan {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;

   $self->log->verbose("scan: using device [$device]");

   my $cmd = "iwlist $device scan";

   my $result = $self->capture($cmd);

   if (@$result > 0) {
      return $self->_list_ap($result);
   }

   return $self->log->error("scan: no result");
}

sub _list_ap {
   my $self = shift;
   my ($scan) = @_;

   my $ap_hash = {};

   my $cell = '';
   my $address = '';
   my $channel = '';
   my $frequency = '';
   my $essid = '';
   my $encryption = '';
   my $raw = [];
   my $quality = '';
   for my $line (@$scan) {
      push @$raw, $line;

      if ($line =~ /^\s+Cell\s+(\d+).*Address:\s+(.*)$/) {
         # We just hit a new Cell, we reset data.
         if (length($cell)) {
            $ap_hash->{"cell_$cell"} = {
               cell => $cell,
               address => $address,
               essid => $essid,
               encryption => $encryption,
               raw => $raw,
               quality => $quality,
            };

            $cell = '';
            $address = '';
            $channel = '';
            $frequency = '';
            $essid = '';
            $encryption = '';
            $raw = [];
            $quality = '';

            # We put back the current line.
            push @$raw, $line;
         }
         $cell = $1;
         $address = $2;
         next;
      }

      if ($line =~ /^\s+Channel:(\d+)/) {
         $channel = $1;
         next;
      }

      if ($line =~ /^\s+Frequency:(\d+\.\d+)/) {
         $frequency = $1;
         next;
      }

      if ($line =~ /^\s+Quality=(\d+)\/(\d+)/) {
         $quality = sprintf("%.2f", 100 * $1 / $2);
         next;
      }

      if ($line =~ /^\s+Encryption key:(\S+)/) {
         my $this = $1;
         if ($this eq 'off') {
            $encryption = 0;
         }
         elsif ($this eq 'on') {
            $encryption = 1;
         }
         else {
            $encryption = -1;
         }
      }

      if ($line =~ /^\s+ESSID:"(\S+)"/) {
         $essid = $1;
         $self->log->verbose("cell [$cell] address [$address] essid[$essid] encryption[$encryption] quality[$quality] channel[$channel] frequency[$frequency]");
         next;
      }

   }

   $ap_hash->{"cell_$cell"} = {
      cell => $cell,
      address => $address,
      channel => $channel,
      frequency => $frequency,
      essid => $essid,
      encryption => $encryption,
      raw => $raw,
      quality => $quality,
   };

   return $ap_hash;
}

sub connect {
   my $self = shift;
   my ($device, $essid) = @_;

   $device ||= $self->device;

   $essid ||= $self->essid;
   if (! defined($essid)) {
      return $self->log->error($self->brik_help_set('essid'));
   }

   my $cmd = "sudo iwconfig $device essid $essid";

   $self->capture_stderr(1);

   my $r = $self->capture($cmd)
      or return $self->log->error("connect: capture failed");

   $self->log->verbose("connect: $r");

   $self->set_bitrate
      or return $self->log->error("connect: set_bitrate failed");

   # For WEP, we can use:
   # "iwconfig $device key $key"

   return $r;
}

sub set_bitrate {
   my $self = shift;
   my ($bitrate, $device) = @_;

   $bitrate ||= $self->bitrate;
   if (! defined($bitrate)) {
      return $self->log->error($self->brik_help_set('bitrate'));
   }

   $device ||= $self->device;

   $self->capture_stderr(1);

   my $cmd = "sudo iwconfig $device rate $bitrate";

   return $self->capture($cmd);
}

sub set_wepkey {
   my $self = shift;
   my ($key, $device) = @_;

   $key ||= $self->key;
   if (! defined($key)) {
      return $self->log->error($self->brik_help_set('key'));
   }

   $device ||= $self->device;

   my $cmd = "sudo iwconfig $device key $key";

   $self->capture_stderr(1);

   return $self->capture($cmd);
}

sub start_monitor_mode {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;

   # airmon-ng is optional, so we check here.
   my $found = $self->brik_check_require_binaries({ 'airmon-ng' => [ ] });
   if (! $found) {
      return $self->log->error("start_monitor_mode: you have to install aircrack-ng package");
   }

   my $cmd = "sudo airmon-ng start $device";

   $self->capture_stderr(1);

   my $r = $self->capture($cmd);

   if (defined($r)) {
      my $monitor = '';
      for my $line (@$r) {
         if ($line =~ /monitor mode enabled on (\S+)\)/) {
            $monitor = $1;
            last;
         }
      }

      if (! length($monitor)) {
         return $self->log->error("start_monitor_mode: cannot start monitor mode");
      }

      if ($monitor !~ /^[a-z]+(?:\d+)?$/) {
         return $self->log->error("start_monitor_mode: cannot start monitor mode with monitor [$monitor]");
      }

      $self->monitor($monitor);
      $self->_monitor_mode_started(1);
   }

   return $self->monitor;
}

sub stop_monitor_mode {
   my $self = shift;
   my ($monitor) = @_;

   if (! $self->_monitor_mode_started) {
      return $self->log->error($self->brik_help_run('start_monitor_mode'));
   }

   $monitor ||= $self->monitor;

   # airmon-ng is optional, so we check here.
   my $found = $self->brik_check_require_binaries({ 'airmon-ng' => [ ] });
   if (! $found) {
      return $self->log->error("stop_monitor_mode: you have to install aircrack-ng package");
   }

   my $cmd = "sudo airmon-ng stop $monitor";

   $self->capture_stderr(1);

   my $r = $self->capture($cmd);

   if (defined($r)) {
      $self->_monitor_mode_started(0);
   }

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Network::Wlan - network::wlan Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
