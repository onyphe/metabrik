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
         lookup => [ qw(ipv4_address) ],
         update => [ ],
      },
      require_binaries => {
         'dig', => [ ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my @urls = qw(
      ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
      ftp://ftp.ripe.net/ripe/stats/delegated-ripencc-latest
      ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest
      ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-latest
      ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest
   );

   my @whois = qw(
      ftp://ftp.ripe.net/ripe/dbase/split/ripe.db.inetnum.gz
      ftp://ftp.afrinic.net/dbase/afrinic.db.gz
      ftp://ftp.apnic.net/apnic/whois-data/APNIC/split/apnic.db.inetnum.gz
      http://ftp.apnic.net/apnic/dbase/data/jpnic.db.gz
      http://ftp.apnic.net/apnic/dbase/data/krnic.db.gz
      http://ftp.apnic.net/apnic/dbase/data/twnic.in.gz
      http://ftp.apnic.net/apnic/dbase/data/twnic.pn.gz
   );

   my $www = Metabrik::Client::Www->new_from_brik($self);

   for my $url (@urls) {
      $self->log->verbose("update: GETing url [$url]");
      my $get = $www->get($url);
      if (! defined($get)) {
         $self->log->warning("update: can't GET file url [$url]");
         next;
      }

      (my $filename = $url) =~ s/^.*\/(.*?)$/$1/;

      my $text = Metabrik::File::Text->new_from_brik($self);
      $text->append(0);
      $text->overwrite(1);
      $text->output($self->global->datadir."/$filename.whois");
      $text->write($get->{body});
      last;
   }

   return 1;
}

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
