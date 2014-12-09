#
# $Id$
#
# network::whois Brik
#
package Metabrik::Network::Whois;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable whois as country cymru) ],
      commands => {
         lookup => [ ],
      },
      require_binaries => {
         'dig', => [ ],
      },
   };
}

# ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
# ftp.ripe.net/ripe/stats/delegated-ripencc-latest
# ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest
# ftp.apnic.net/pub/stats/apnic/delegated-apnic-latest
# ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest
# http://www.team-cymru.org/Services/ip-to-asn.html
sub lookup {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      return $self->log->error($self->brik_help_run('lookup'));
   }

   my @toks = split('\.', $ip);
   my $rev = join('.', reverse @toks);

   my $cmd = "dig +short $rev.origin.asn.cymru.com TXT";
   my $res = $self->capture($cmd);
   if (! defined($res)) {
      return $self->log->error("lookup: dig failed [$cmd]");
   }

   my $first = $res->[0];
   $self->log->verbose("lookup: line [$first]");
   $first =~ s/^"//;
   $first =~ s/"$//;
   my @values = split(/\s+\|\s+/, $first);

   my $h = {
      raw => $res,
      ip => $ip,
      as => $values[0],
      subnet => $values[1],
      countrycode => $values[2],
      registrar => $values[3],
      date => $values[4],
   };

   return $h;
}

1;

__END__

=head1 NAME

Metabrik::Network::Whois - network::whois Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
