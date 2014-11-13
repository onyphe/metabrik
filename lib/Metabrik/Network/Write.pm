#
# $Id$
#
# network::write Brik
#
package Metabrik::Network::Write;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network write ethernet ip raw socket) ],
      attributes => {
         device => [ qw(device) ],
         target => [ qw(ipv4_address|ipv6_address) ],
         family => [ qw(ipv4|ipv6) ],
         protocol => [ qw(tcp|udp) ],
         layer => [ qw(2|3|4) ],
         _fd => [ qw(INTERNAL) ],
      },
      commands => {
         open => [ ],
         send => [ qw($data) ],
         close => [ ],
      },
      require_modules => {
         'Net::Write::Layer' => [ ],
         'Net::Write::Layer2' => [ ],
         'Net::Write::Layer3' => [ ],
         'Net::Write::Layer4' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         layer => 2,
         device => $self->global->device,
         family => $self->global->family,
         protocol => $self->global->protocol,
      },
   };
}

sub open {
   my $self = shift;

   my $family = $self->family eq 'ipv6'
      ? Net::Write::Layer::NW_AF_INET6()
      : Net::Write::Layer::NW_AF_INET();

   my $protocol = $self->protocol eq 'udp'
      ? Net::Write::Layer::NW_IPPROTO_UDP()
      : Net::Write::Layer::NW_IPPROTO_TCP();

   my $fd;
   if ($self->layer == 2) {
      $fd = Net::Write::Layer2->new(
         dev => $self->device,
      ) or return $self->log->error("open: layer2: error");
   }
   elsif ($self->layer == 3) {
      if (! defined($self->target)) {
         return $self->log->error($self->brik_help_set('target'));
      }
      $fd = Net::Write::Layer3->new(
         dst => $self->target,
         protocol => Net::Write::Layer::NW_IPPROTO_RAW(),
         family => $family,
      ) or return $self->log->error("open: layer3: error");
   }
   elsif ($self->layer == 4) {
      if (! defined($self->target)) {
         return $self->log->error($self->brik_help_set('target'));
      }
      $fd = Net::Write::Layer4->new(
         dst => $self->target,
         protocol => $protocol,
         family => $family,
      ) or return $self->log->error("open: layer4: error");
   }

   $fd->open or return $self->log->error("open: error");

   $self->_fd($fd);

   return $fd;
}

sub send {
   my $self = shift;
   my ($data) = @_;

   my $fd = $self->_fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('send'));
   }

   $fd->send($data);

   return 1;
}

sub close {
   my $self = shift;

   my $fd = $self->_fd;
   if (! defined($fd)) {
      return 1;
   }

   $fd->close;
   $self->_fd(undef);

   return 1;
}

1;

__END__
