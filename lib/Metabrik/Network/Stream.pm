#
# $Id$
#
# network::stream Brik
#
package Metabrik::Network::Stream;
use strict;
use warnings;

use base qw(Metabrik::Network::Read);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      attributes => {
         device => [ qw(device) ],
         filter => [ qw(filter) ],
         protocol => [ qw(udp|tcp) ],
      },
      attributes_default => {
         filter => '',
         protocol => 'tcp',
      },
      commands => {
         from_pcap => [ qw(file filter|OPTIONAL) ],
      },
      require_modules => {
         'Net::Frame::Simple' => [ ],
         'Metabrik::File::Pcap' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device,
      },
   };
}

sub from_pcap {
   my $self = shift;
   my ($file, $filter) = @_;

   $filter ||= $self->filter;
   if (! defined($file)) {
      return $self->log->error($self->brik_help_run('from_pcap'));
   }
   if (! -f $file) {
      return $self->log->error("from_pcap: file [$file] not found");
   }

   my $fp = Metabrik::File::Pcap->new_from_brik_init($self) or return;
   $fp->open($file, $filter) or return;

   {
      # So we can interrupt execution
      local $SIG{INT} = sub {
         die("interrupted by user\n");
      };

      while (1) {
         my $h = $fp->read_next;
         last if @$h == 0;
         for my $this (@$h) {
            my $simple = Net::Frame::Simple->newFromDump($this) or next;
            my $layer = $simple->ref->{TCP} || $simple->ref->{UDP};
            if (defined($layer) && length($layer->payload)) {
               my $src = $simple->ref->{IPv4}->src || $simple->ref->{IPv6}->src;
               my $dst = $simple->ref->{IPv4}->dst || $simple->ref->{IPv6}->dst;
               my $payload = $layer->payload;
               $self->log->info("payload: $src > $dst: [".unpack('H*', $payload)."]");
            }
         }
      }
   };

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Network::Stream - network::stream Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
