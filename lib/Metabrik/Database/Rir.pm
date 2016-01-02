#
# $Id$
#
# database::rir Brik
#
package Metabrik::Database::Rir;
use strict;
use warnings;

# Some history:
# http://www.apnic.net/about-APNIC/organization/history-of-apnic/history-of-the-regional-internet-registries

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable as country subnet) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
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
         ip_to_asn => [ qw(ipv4_address) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
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

   my $datadir = $self->datadir;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;

   my @fetched = ();
   for my $url (@urls) {
      $self->log->verbose("update: fetching url [$url]");

      (my $filename = $url) =~ s/^.*\/(.*?)$/$1/;

      my $output = $datadir.'/'.$filename;
      my $r = $cw->mirror($url, $filename, $datadir);
      if (! defined($r)) {
         $self->log->warning("update: can't fetch url [$url]");
         next;
      }
      if (@$r == 0) { # Nothing new
         next;
      }
      push @fetched, $output;
   }

   return \@fetched;
}

sub next_record {
   my $self = shift;
   my ($input) = @_;

   my $fr = $self->_read;
   if (! defined($fr)) {
      $input ||= $self->datadir.'/'.$self->input;
      $self->brik_help_run_file_not_found('next_record', $input) or return;

      $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
      $fr->encoding('ascii');
      $fr->input($input);
      $fr->as_array(0);
      $fr->open or return;
      $self->_read($fr);
   }

   # 2|afrinic|20150119|4180|00000000|20150119|00000
   # afrinic|*|asn|*|1146|summary
   # afrinic|*|ipv4|*|2586|summary
   # afrinic|*|ipv6|*|448|summary
   # afrinic|ZA|asn|1228|1|19910301|allocated

   my $line;
   while ($line = $fr->read_line) {
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

sub ip_to_asn {
   my $self = shift;
   my ($ip) = @_;

   return $self;
}

1;

__END__

=head1 NAME

Metabrik::Database::Rir - database::rir Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
