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
      tags => [ qw(unstable location ipv4 ipv6 ip geo geolocation) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      commands => {
         update => [ ],
         from_ip => [ qw(ip_address) ],
         from_ipv4 => [ qw(ipv4_address) ],
         from_ipv6 => [ qw(ipv6_address) ],
         subnet4 => [ qw(ipv4_address) ],
         organization_name => [ qw(ip_address) ],
      },
      require_modules => {
         'Geo::IP' => [ ],
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my $dl_path = 'http://geolite.maxmind.com/download/geoip/database/';

   my %mirror = (
      'GeoIP.dat.gz' => 'GeoLiteCountry/GeoIP.dat.gz',
      'GeoIPCity.dat.gz' => 'GeoLiteCity.dat.gz',
      'GeoIPv6.dat.gz' => 'GeoIPv6.dat.gz',
      'GeoIPASNum.dat.gz' => 'asnum/GeoIPASNum.dat.gz'
   );

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->user_agent("Metabrik-MaxMind-geolite-mirror/1.01");
   $cw->datadir($datadir);

   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   $fc->datadir($datadir);

   for my $f (keys %mirror) {
      my $files = $cw->mirror($dl_path.$mirror{$f}, $f) or next;
      for my $file (@$files) {
         (my $outfile = $file) =~ s/\.gz$//;
         $self->log->verbose("update: uncompressing to [$outfile]");
         $fc->uncompress($datadir.'/'.$file, $outfile) or next;
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

   my $gi = Geo::IP->open($self->datadir.'/GeoIPCity.dat', Geo::IP::GEOIP_STANDARD())
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

sub subnet4 {
   my $self = shift;
   my ($ipv4_address) = @_;

   if (! defined($ipv4_address)) {
      return $self->log->error($self->brik_help_run('subnet4'));
   }

   my $gi = Geo::IP->open($self->datadir.'/GeoIPCity.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("subnet4: unable to open GeoIPCity.dat");

   my ($from, $to) = $gi->range_by_ip($ipv4_address);

   return [ $from, $to ];
}

sub organization_name {
   my $self = shift;
   my ($ip_address) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('organization_name'));
   }
  
   my $gi = Geo::IP->open($self->datadir.'/GeoIPCity.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("organization_name: unable to open GeoIPCity.dat");

   my $record = $gi->name_by_addr($ip_address);

   return $record;
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