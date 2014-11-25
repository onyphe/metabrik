#
# $Id$
#
# address::netmask Brik
#
package Metabrik::Address::Netmask;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable address netmask) ],
      attributes => {
         subnet => [ qw(subnet) ],
      },
      attributes_default => {
         subnet => '192.168.0.0/24',
      },
      commands => {
         match => [ qw(ipv4_address) ],
         first => [ ],
         last => [ ],
         block => [ ],
         iplist => [ ],
      },
      require_modules => {
         'Net::Netmask' => [ ],
      },
   };
}

sub match {
   my $self = shift;
   my ($ip) = @_;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   if ($block->match($ip)) {
      print "$ip is in the same subnet as $subnet\n";
   }
   else {
      print "$ip is NOT in the same subnet as $subnet\n";
   }

   return 1;
}

sub block {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   return $block;
}

sub iplist {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   my @ip_list = $block->enumerate;

   return \@ip_list;
}

sub first {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   print $block->first."\n";

   return 1;
}

sub last {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   print $block->last."\n"; 

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Address::Netmask - address::netmask Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
