#
# $Id$
#
# lookup::ethernet Brik
#
package Metabrik::Lookup::Ethernet;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable lookup ethernet) ],
      commands => {
         int => [ qw(int_number) ],
         hex => [ qw(hex_number) ],
         string => [ qw(ethernet_type) ],
      },
   };
}

sub _lookup {
   my $self = shift;

   my $lookup = {
      '0x0800' => 'ipv4',
      '0x0805' => 'x25',
      '0x0806' => 'arp',
      '0x2001' => 'cgmp',
      '0x2452' => '802.11',
      '0x8021' => 'pppipcp',
      '0x8035' => 'rarp',
      '0x809b' => 'ddp',
      '0x80f3' => 'aarp',
      '0x80fd' => 'pppccp',
      '0x80ff' => 'wcp',
      '0x8100' => '802.1q',
      '0x8137' => 'ipx',
      '0x8181' => 'stp',
      '0x86dd' => 'ipv6',
      '0x872d' => 'wlccp',
      '0x8847' => 'mpls',
      '0x8863' => 'pppoed',
      '0x8864' => 'pppoes',
      '0x888e' => '802.1x',
      '0x88a2' => 'aoe',
      '0x88c7' => '802.11i',
      '0x88cc' => 'lldp',
      '0x88d9' => 'lltd',
      '0x9000' => 'loop',
      '0x9100' => 'vlan',
      '0xc023' => 'ppppap',
      '0xc223' => 'pppchap',
   };

   return $lookup;
}

sub hex {
   my $self = shift;
   my ($hex) = @_;

   if (! defined($hex)) {
      return $self->log->error($self->brik_help_run('hex'));
   }

   $hex =~ s/^0x//;
   if ($hex !~ /^[0-9a-f]+$/i) {
      return $self->log->error("hex: invalid format for hex [$hex]");
   }
   $hex = sprintf("0x%04s", $hex);

   return $self->_lookup->{$hex} || 'unknown';
}

sub int {
   my $self = shift;
   my ($int) = @_;

   if (! defined($int)) {
      return $self->log->error($self->brik_help_run('int'));
   }

   if ($int !~ /^[0-9]+$/) {
      return $self->log->error("int: invalid format for int [$int]");
   }
   my $hex = sprintf("0x%04x", $int);

   return $self->hex($hex);
}

sub string {
   my $self = shift;
   my ($string) = @_;

   if (! defined($string)) {
      return $self->log->error($self->brik_help_run('string'));
   }

   my $lookup = $self->_lookup;

   my $rev = {};
   while (my ($key, $val) = each(%$lookup)) {
      $rev->{$val} = $key;
   }

   return $rev->{$string} || 'unknown';
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Ethernet - lookup::ethernet Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
