#
# $Id$
#
# network::ssdp brik
#
package Metabrik::Network::Ssdp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(experimental network ssdp) ],
      attributes => {
         device => [ qw(device) ],
      },
      commands => {
         discover => [ ],
      },
      require_modules => {
         'IO::Socket::Multicast' => [ ],
      },
   };
}

sub discover {
   my $self = shift;

   if (! defined($self->device)) {
      return $self->log->error($self->brik_help_set('device'));
   }

   my $device = $self->device;

   my $ssdpAddr = '239.255.255.250';
   my $ssdpPort = 1900;

   my $m = IO::Socket::Multicast->new(
      Proto     => 'udp',
      #LocalPort => 1900,
      PeerDest  => $ssdpAddr,
      PeerPort  => $ssdpPort,
      ReuseAddr => 1,
   ) or return $self->log->error("multicast: $!");
   $m->mcast_if($device);

   my $ssdpSearch =
      "M-SEARCH * HTTP/1.1\r\n".
      "Host: $ssdpAddr:$ssdpPort\r\n".
      "Man: \"ssdp:discover\"\r\n".
      "ST: upnp:rootdevice\r\n".
      "MX: 3\r\n".
      "\r\n".
      "";

   # XXX: use IO::Select to handle timeout

   my $data;
   for (1..3) {
      $m->mcast_send($ssdpSearch, "$ssdpAddr:$ssdpPort") or $self->log->error("mcast_send: $!");
      print "[+] Request sent\n";
      $m->recv($data, 1024);
      if ($data && length($data)) {
         print "[+] Answer received\n";
         last;
      }
      sleep(1);
   }

   print $data;

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::Network::Ssdp - network::ssdp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
