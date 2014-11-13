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
      tags => [ qw(unstable wifi wlan network) ],
      attributes => {
         device => [ qw(device) ],
         _scan => [ ],
      },
      attributes_default => {
         device => 'wlan0',
      },
      commands => {
         scan => [ ],
         flush => [ ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'iwlist', => [ ],
      },
   };
}

sub scan {
   my $self = shift;

   my $scan = $self->_scan;
   if (defined($scan)) {
      return $scan;
   }

   my $device = $self->device;
   my $context = $self->context;

   $self->log->verbose("scan: using device [$device]");

   my $cmd = "iwlist $device scan";
   my $result = $context->run('shell::command', 'capture', $cmd);

   return $self->_scan($result);
}

sub flush {
   my $self = shift;

   $self->_scan(undef);

   return 1;
}

1;

__END__
