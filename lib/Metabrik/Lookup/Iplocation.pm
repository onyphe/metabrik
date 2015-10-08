#
# $Id$
#
# lookup::iplocation Brik
#
package Metabrik::Lookup::Iplocation;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable lookup location ipv4 ipv6 ip) ],
      attributes => {
         datadir => [ qw(datadir) ],
      },
      commands => {
         update => [ ],
         from_ip => [ qw(ip_address) ],
         from_ipv4 => [ qw(ipv4_address) ],
         from_ipv6 => [ qw(ipv6_address) ],
      },
      require_modules => {
         'Geo::IP' => [ ],
         'LWP::Simple' => [ ],
         'File::Copy' => [ ],
         'File::Spec' => [ ],
         'PerlIO' => [ ],
         'PerlIO::gzip' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my $ua;
   eval('use LWP::Simple qw(mirror RC_NOT_MODIFIED RC_OK $ua);');
   eval('use File::Copy qw(mv);');

   my $download_dir = $self->datadir;
   my $dest_dir = $self->datadir;

   my %mirror = (
      'GeoIP.dat.gz'      => 'GeoLiteCountry/GeoIP.dat.gz',
      'GeoIPCity.dat.gz'  => 'GeoLiteCity.dat.gz',
      'GeoIPv6.dat.gz'    => 'GeoIPv6.dat.gz',
      'GeoIPASNum.dat.gz' => 'asnum/GeoIPASNum.dat.gz'
   );

   $ua->agent("Metabrik-MaxMind-geolite-mirror/1.00");
   my $dl_path = 'http://geolite.maxmind.com/download/geoip/database/';

   chdir($download_dir)
      or return $self->log->error("update: unable to chdir to [$download_dir]: $!");
   for my $f (keys %mirror) {
      my $rc = mirror($dl_path.$mirror{$f}, $f);
      if ($rc == RC_NOT_MODIFIED()) {
         next;
      }
      if ($rc == RC_OK()) {
         (my $outfile = $f) =~ s/\.gz$//;
         my $r = open(my $in, '<:gzip', $f);
         if (! defined($r)) {
            $self->log->error("update: unable to unzip file [$f]: $!");
            next;
         }
         $r = open(my $out, '>', $outfile);
         if (! defined($r)) {
            $self->log->error("update: unable to open file [$outfile]: $!");
            next;
         }
         while (<$in>) {
            print $out $_
               or $self->log->error("update: unable to write to file [$outfile]: $!");
         }
         $r = mv($outfile, File::Spec->catfile($dest_dir, $outfile));
         if (! defined($r)) {
            $self->log->error("update: unable to move file [$outfile] to [$dest_dir]: $!");
            next;
         }

         $self->log->info("update: file [$outfile] created or updated in [$dest_dir]");
      }
   }

   return 1;
}

sub from_ipv4 {
   my $self = shift;
   my ($ipv4) = @_;

   if (! defined($ipv4)) {
      return $self->log->error($self->brik_help_run('from_ipv4'));
   }

   my $gi = Geo::IP->open($self->datadir.'/GeoIPCity.dat', GEOIP_STANDARD())
      or return $self->log->error("from_ipv4: unable to open GeoIPCity.dat");

   my $record = $gi->record_by_addr($ipv4);

   # Convert from blessed hashref to hashref
   return { map { $_ => $record->{$_} } keys %$record };
}

sub from_ipv6 {
   my $self = shift;
   my ($ipv6) = @_;

   if (! defined($ipv6)) {
      return $self->log->error($self->brik_help_run('from_ipv6'));
   }

   my $gi = Geo::IP->open($self->datadir.'/GeoIPv6.dat')
      or return $self->log->error("from_ipv6: unable to open GeoIPv6.dat");

   my $record = $gi->country_code_by_addr_v6($ipv6);

   # Convert from blessed hashref to hashref
   return { map { $_ => $record->{$_} } keys %$record };
}

sub from_ip {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      return $self->log->error($self->brik_help_run('from_ip'));
   }

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if ($na->is_ipv4($ip)) {
      return $self->from_ipv4($ip);
   }
   elsif ($na->is_ipv6($ip)) {
      return $self->from_ipv6($ip);
   }

   $self->log->info("from_ip: IP [$ip] is not a valid IP address");

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Iplocation - lookup::iplocation Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
