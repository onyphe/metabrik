#
# $Id$
#
# network::whois Brik
#
package Metabrik::Network::Whois;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network whois) ],
      attributes => {
         rtimeout => [ qw(timeout) ],
      },
      attributes_default => {
         rtimeout => 2,
      },
      commands => {
         target => [ qw(domain|ip_address) ],
      },
      require_modules => {
         'Net::Whois::Raw' => [ ],
         'Metabrik::String::Parse' => [ ],
      },
   };
}

sub target {
   my $self = shift;
   my ($target) = @_;

   if (! defined($target)) {
      return $self->log->error($self->brik_help_run('target'));
   }

   $Net::Whois::Raw::TIMEOUT = $self->rtimeout;

   my $info = Net::Whois::Raw::whois($target)
      or return $self->log->error("target: whois for target [$target] failed");

   my $sp = Metabrik::String::Parse->new_from_brik_init($self) or return;
   my $lines = $sp->to_array($info) or return;

   return $lines;
}

1;

__END__

=head1 NAME

Metabrik::Network::Whois - network::whois Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
