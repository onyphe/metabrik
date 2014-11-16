#
# $Id$
#
# network::frame Brik
#
package Metabrik::Network::Frame;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(TODO frame packet network) ],
      commands => {
         from_read => [ ],
         from_hexa => [ ],
         show => [ ],
      },
      require_used => {
         'encoding::hexa' => [ ],
      },
      require_modules => {
         'Net::Frame::Simple' => [ ],
         'Net::Frame::Layer::ARP' => [ ],
         'Net::Frame::Layer::ETH' => [ ],
         'Net::Frame::Layer::IPv4' => [ ],
         'Net::Frame::Layer::IPv6' => [ ],
         'Net::Frame::Layer::TCP' => [ ],
         'Net::Frame::Layer::UDP' => [ ],
         'Net::Frame::Layer::ICMPv4' => [ ],
         'Net::Frame::Layer::ICMPv6' => [ ],
      },
   };
}

sub from_read {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('from_read'));
   }

   if (ref($data) ne 'HASH') {
      return $self->log->error("from_read: data must be a HASHREF");
   }

   if (! exists($data->{raw})
   ||  ! exists($data->{firstLayer})
   ||  ! exists($data->{timestamp})) {
      return $self->log->error("from_read: data must be come from network::read Brik");
   }

   return Net::Frame::Simple->newFromDump($data);
}

sub from_hexa {
   my $self = shift;
   my ($data) = @_;

   my $context = $self->context;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('from_hexa'));
   }

   if (! $context->run('encoding::hexa', 'is_hexa', $data)) {
      return $self->log->error('from_hexa: data is not hexa');
   }

   my $raw = $context->run('encoding::hexa', 'decode', $data);

   return Net::Frame::Simple->new(raw => $raw, firstLayer => 'ETH');
}

sub show {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('show'));
   }

   if (ref($data) ne 'Net::Frame::Simple') {
      return $self->log->error("from_read: data must come from from_read Command");
   }

   my $str = $data->print;

   print $str."\n";

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Frame - network::frame Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
