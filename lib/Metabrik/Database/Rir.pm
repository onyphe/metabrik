#
# $Id$
#
# database::rir Brik
#
package Metabrik::Database::Rir;
use strict;
use warnings;

# XXX: use IP::Country?

# Some history:
# http://www.apnic.net/about-APNIC/organization/history-of-apnic/history-of-the-regional-internet-registries

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable database rir as country subnet) ],
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(input.rir) ],
         _read => [ qw(INTERNAL) ],
      },
      attributes_default => {
         input => 'input.rir',
      },
      commands => {
         update => [ ],
         next_record => [ qw(input|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Fetch' => [ ],
         'Metabrik::File::Read' => [ ],
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

   my $file_fetch = Metabrik::File::Fetch->new_from_brik($self) or return;

   my @fetched = ();
   for my $url (@urls) {
      $self->log->verbose("update: fetching url [$url]");

      (my $filename = $url) =~ s/^.*\/(.*?)$/$1/;

      my $output = $self->datadir.'/'.$filename;
      my $get = $file_fetch->get($url, $output);
      if (! defined($get)) {
         $self->log->warning("update: can't fetch url [$url]");
         next;
      }
      push @fetched, $output;
   }

   return \@fetched;
}

sub next_record {
   my $self = shift;
   my ($input) = @_;

   my $read = $self->_read;
   if (! defined($read)) {
      $input ||= $self->datadir.'/'.$self->input;
      if (! -f $input) {
         return $self->log->error("next_record: file [$input] does not exist");
      }

      $read = Metabrik::File::Read->new_from_brik($self) or return;
      $read->encoding('ascii');
      $read->input($input);
      $read->as_array(0);
      $read->open
         or return $self->log->error("next_record: file::read open failed");
      $self->_read($read);
   }

   # 2|afrinic|20150119|4180|00000000|20150119|00000
   # afrinic|*|asn|*|1146|summary
   # afrinic|*|ipv4|*|2586|summary
   # afrinic|*|ipv6|*|448|summary
   # afrinic|ZA|asn|1228|1|19910301|allocated

   my $line;
   while ($line = $read->read_line) {
      next if $line =~ /^\s*#/;  # Skip comments

      chomp($line);

      $self->debug && $self->log->debug("next_record: line[$line]");

      my @t = split(/\|/, $line);

      my $cc = $t[1];
      if (! defined($cc)) {
         $self->log->verbose("next_record: skipping line [$line]");
         next;
      }
      next if ($cc eq '*');

      my $type = $t[2];
      if (! defined($type)) {
         $self->log->verbose("next_record: skipping line [$line]");
         next;
      }
      next if ($type ne 'asn' && $type ne 'ipv4' && $type ne 'ipv6');

      # XXX: TODO, convert IPv4 to int and add $count, then convert to x-subnet

      my $rir = $t[0];
      my $value = $t[3];
      my $count = $t[4];
      my $date = $t[5];
      my $status = $t[6];

      if ($date !~ /^\d{8}$/) {
         $self->log->verbose("next_record: invalid date [$date] for line [$line]");
         $date = '1970-01-01';
      }
      else {
         $date =~ s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
      }

      my $h = {
         raw => $line,
         rir => $rir,
         cc => $cc,
         type => $type,
         value => $value,
         count => $count,
         'rir-date' => $date,
         status => $status,
      };

      return $h;
   }

   return;
}

1;

__END__

=head1 NAME

Metabrik::Database::Rir - database::rir Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
