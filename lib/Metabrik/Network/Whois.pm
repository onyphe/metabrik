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
      commands => {
         domain => [ qw(domain) ],
      },
      require_modules => {
         'Net::Whois::Raw' => [ ],
         'Metabrik::String::Parse' => [ ],
      },
   };
}

sub domain {
   my $self = shift;
   my ($domain) = @_;

   if (! defined($domain)) {
      return $self->log->error($self->brik_help_run('domain'));
   }

   if ($domain !~ /^\S+\.\S+$/) {
      return $self->log->error("domain: invalid format for domain [$domain]");
   }

   my $info = Net::Whois::Raw::whois($domain)
      or return $self->log->error("domain: whois failed");

   my $parse_string = Metabrik::String::Parse->new_from_brik($self) or return;
   my $lines = $parse_string->to_array($info)
      or return $self->log->error("domain: to_array failed");

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
