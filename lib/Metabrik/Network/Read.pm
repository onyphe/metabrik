#
# $Id$
#
# network::read Brik
#
package Metabrik::Network::Read;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network read ethernet ip raw socket) ],
      attributes => {
         device => [ qw(device) ],
         rtimeout => [ qw(seconds) ],
         family => [ qw(ipv4|ipv6) ],
         protocol => [ qw(tcp|udp) ],
         layer => [ qw(2|3|4) ],
         filter => [ qw(pcap_filter) ],
         max_read => [ qw(integer_packet_count) ],
         _fd => [ qw(SCALAR) ],
      },
      commands => {
         open => [ ],
         next => [ ],
         next_until_timeout => [ ],
         close => [ ],
      },
      require_modules => {
         'Net::Frame::Dump' => [ ],
         'Net::Frame::Dump::Online2' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         layer => 2,
         rtimeout => $self->global->rtimeout,
         device => $self->global->device,
         family => $self->global->family,
         protocol => $self->global->protocol,
         max_read => 10,
      },
   };
}

sub open {
   my $self = shift;

   my $family = $self->family eq 'ipv6' ? 'ip6' : 'ip';

   my $protocol = defined($self->protocol) ? $self->protocol : 'tcp';

   my $filter = $self->filter || '';

   my $fd;
   if ($self->layer == 2) {
      $fd = Net::Frame::Dump::Online2->new(
         dev => $self->device,
         timeoutOnNext => $self->rtimeout,
         filter => $filter,
      );
   }
   elsif ($self->layer != 3) {
      return $self->log->error("open: not implemented");
   }

   $fd->start or return $self->log->error("open: error");

   $self->_fd($fd);

   return $fd;
}

sub next {
   my $self = shift;

   my $fd = $self->_fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $next = $fd->next;

   return defined($next) ? $next : 'undef';
}

sub next_until_timeout {
   my $self = shift;

   my $fd = $self->_fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $rtimeout = $self->rtimeout;
   my $max_read = $self->max_read;
   $self->log->verbose("next_until_timeout: will read until $rtimeout seconds or $max_read packet(s) has been read");

   my $count = 0;
   my @next = ();
   while (! $fd->timeout) {
      if ($max_read && $count == $max_read) {
         last;
      }

      if (my $next = $fd->next) {
         push @next, $next;
         $self->log->verbose("next_until_timeout: read one packet");
         $count++;
      }
   }
   $fd->timeoutReset;

   return \@next;
}

sub close {
   my $self = shift;

   my $fd = $self->_fd;
   if (! defined($fd)) {
      return 1;
   }

   $fd->stop;
   $self->_fd(undef);

   return 1;
}

1;

__END__
