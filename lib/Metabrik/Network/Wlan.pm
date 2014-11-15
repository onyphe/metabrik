#
# $Id$
#
# network::wlan Brik
#
package Metabrik::Network::Wlan;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable wifi wlan network monitor) ],
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
         scan => [ ],
         set_bitrate => [ qw(bitrate|$self::bitrate) ],
         set_wepkey => [ qw(bitrate|$self::key) ],
         connect => [ ],
         start_monitor_mode => [ ],
         stop_monitor_mode => [ ],
      },
      require_used => {
         'shell::command' => [ ],
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

   my $device = $self->device;
   my $context = $self->context;

   $self->log->verbose("scan: using device [$device]");

   my $old = $context->get('shell::command', 'as_matrix');
   $context->set('shell::command', 'as_matrix', 0);

   my $cmd = "iwlist $device scan";
   my $result = $context->run('shell::command', 'capture', $cmd);

   $context->set('shell::command', 'as_matrix', $old);

   if (length($result)) {
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

   my $essid = $self->essid;
   if (! defined($essid)) {
      return $self->log->error($self->brik_help_set('essid'));
   }

   my $context = $self->context;
   my $device = $self->device;

   my $cmd = "iwconfig $device essid $essid";
   my $r = $context->run('shell::command', 'capture', $cmd)
      or return;

   $self->log->verbose("connect: $r");

   $self->set_bitrate or return;

   # For WEP, we can use:
   # "iwconfig $device key $key"

   return $r;
}

sub set_bitrate {
   my $self = shift;
   my ($value) = @_;

   $value ||= $self->bitrate;
   if (! defined($value)) {
      return $self->log->error($self->brik_help_set('bitrate'));
   }

   my $context = $self->context;
   my $device = $self->device;

   my $cmd = "iwconfig $device rate $value";
   return $context->run('shell::command', 'capture', $cmd);
}

sub set_wepkey {
   my $self = shift;
   my ($value) = @_;

   $value ||= $self->key;
   if (! defined($value)) {
      return $self->log->error($self->brik_help_set('key'));
   }

   my $context = $self->context;
   my $device = $self->device;

   my $cmd = "iwconfig $device key $value";
   return $context->run('shell::command', 'capture', $cmd);
}

sub start_monitor_mode {
   my $self = shift;

   my $context = $self->context;
   my $device = $self->device;

   # airmon-ng is optional, so we check here.
   my $found = $self->brik_check_require_binaries({ 'airmon-ng' => [ ] });
   if (! $found) {
      return $self->log->error("start_monitor_mode: you have to install aircrack-ng package");
   }

   my $old = $context->get('shell::command', 'as_matrix');

   my $cmd = "sudo airmon-ng start $device";
   my $r = $context->run('shell::command', 'capture', $cmd)
      or return;
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

   $context->set('shell::command', 'as_matrix', $old);

   return $self->monitor;
}

sub stop_monitor_mode {
   my $self = shift;

   if (! $self->_monitor_mode_started) {
      return $self->log->error($self->brik_help_run('start_monitor_mode'));
   }

   my $context = $self->context;
   my $monitor = $self->monitor;

   # airmon-ng is optional, so we check here.
   my $found = $self->brik_check_require_binaries({ 'airmon-ng' => [ ] });
   if (! $found) {
      return $self->log->error("stop_monitor_mode: you have to install aircrack-ng package");
   }

   my $cmd = "sudo airmon-ng stop $monitor";
   my $r = $context->run('shell::command', 'capture', $cmd);
   if (defined($r)) {
      $self->_monitor_mode_started(0);
   }

   return $r;
}

1;

__END__
