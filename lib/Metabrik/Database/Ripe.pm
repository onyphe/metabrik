#
# $Id$
#
# database::ripe Brik
#
package Metabrik::Database::Ripe;
use strict;
use warnings;

# API RIPE search : http://rest.db.ripe.net/search?query-string=193.6.223.152/24
# https://github.com/RIPE-NCC/whois/wiki/WHOIS-REST-API

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable netname country as) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(ripe.db) ],
         _read => [ qw(INTERNAL) ],
      },
      attributes_default => {
         input => 'ripe.db',
      },
      commands => {
         update => [ ],
         next_record => [ qw(file.ripe|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   # Other data than RIPE is not available anymore.
   #ftp://ftp.afrinic.net/dbase/afrinic.db.gz
   #ftp://ftp.apnic.net/apnic/whois-data/APNIC/split/apnic.db.inetnum.gz
   #http://ftp.apnic.net/apnic/dbase/data/jpnic.db.gz
   #http://ftp.apnic.net/apnic/dbase/data/krnic.db.gz
   #http://ftp.apnic.net/apnic/dbase/data/twnic.in.gz
   #http://ftp.apnic.net/apnic/dbase/data/twnic.pn.gz
   my @urls = qw(
      ftp://ftp.ripe.net/ripe/dbase/ripe.db.gz
   );

   my $datadir = $self->datadir;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;

   my @fetched = ();
   for my $url (@urls) {
      $self->log->verbose("update: fetching url [$url]");

      (my $filename = $url) =~ s/^.*\/(.*?)$/$1/;
      (my $unzipped = $filename) =~ s/\.gz$//;

      my $output = $datadir."/$filename";
      my $r = $cw->mirror($url, $filename, $datadir);
      if (! defined($r)) {
         $self->log->warning("update: can't fetch url [$url]");
         next;
      }
      elsif (@$r == 0) { # Already up to date
         next;
      }

      $self->log->verbose("update: gunzipping file to [$unzipped]");

      my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
      my $gunzip = $fc->gunzip($output, $unzipped, $datadir);
      if (! defined($gunzip)) {
         $self->log->warning("update: can't gunzip file [$output]");
         next;
      }
      push @fetched, $unzipped;
   }

   return \@fetched;
}

sub next_record {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->datadir.'/'.$self->input;
   if (! -f $input) {
      return $self->log->error("next_record: file [$input] does not exist");
   }

   my $read = $self->_read;
   if (! defined($read)) {
      $read = Metabrik::File::Read->new_from_brik($self) or return;
      $read->encoding('ascii');
      $read->input($input);
      $read->as_array(1);
      $read->open
         or return $self->log->error("next_record: file::read open failed");
      $self->_read($read);
   }

   my $lines = $read->read_until_blank_line;
   if (@$lines == 0) {
      # If nothing has been read and eof reached, we return undef.
      # Otherwise, we return an empty object.
      return $read->eof ? undef : {};
   }

   my %record = ();
   for my $line (@$lines) {
      next if ($line =~ /^\s*#/);

      my ($key, $val);
      if ($line =~ /^(.*?)\s*:\s*(.*)$/) {
         $key = $1;
         $val = $2;
      }
      next unless defined($val);

      push @{$record{raw}}, $line;

      $self->debug && $self->log->debug("next_record: key [$key] val[$val]");

      if (! exists($record{$key})) {
         $record{$key} = $val;
      }
      else {
         $record{$key} .= "\n$val";
      }

      # Remove DUMMY data, it is kept in {raw} anyway
      delete $record{'remarks'};
      delete $record{'admin-c'};
      delete $record{'tech-c'};
      delete $record{'changed'};
   }

   return \%record;
}

1;

__END__

=head1 NAME

Metabrik::Database::Ripe - database::ripe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
