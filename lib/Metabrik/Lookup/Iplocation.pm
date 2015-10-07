#
# $Id$
#
# lookup::iplocation Brik
#
package Metabrik::Lookup::Iplocation;
use strict;
use warnings;

use base qw(Metabrik::File::Csv);

# XXX: switch to Geo::IP for perf?

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable lookup location ipv4 ipv6 ip) ],
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(input) ],
         _load => [ qw(INTERNAL) ],
      },
      attributes_default => {
         input => 'GeoIPCountryWhois.csv',
         separator => ',',
      },
      commands => {
         update => [ qw(output|OPTIONAL) ],
         load => [ qw(input|OPTIONAL) ],
         from_ip => [ qw(ip_address) ],
         from_ipv4 => [ qw(ipv4_address) ],
         from_ipv6 => [ qw(ipv6_address) ],
      },
      require_modules => {
         'Metabrik::File::Fetch' => [ ],
         'Metabrik::File::Compress' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
   };
}

sub update {
   my $self = shift;
   my ($output) = @_;

   # IPv6
   # 'http://geolite.maxmind.com/download/geoip/database/GeoIPv6.csv.gz'
   # City IPv4
   # 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCity_CSV/GeoLiteCity-latest.zip'
   # City IPv6
   # 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.csv.gz'
   # ASN IPv4
   # 'http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum2.zip'
   # ASN IPv6
   # 'http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum2v6.zip'

   # IPv4
   my $url = 'http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip';
   my ($file) = $self->input;

   $output ||= $self->datadir.'/'.$file.'.zip';

   my $ff = Metabrik::File::Fetch->new_from_brik_init($self) or return;
   $ff->get($url, $output)
      or return $self->log->error("update: get failed");

   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   $fc->datadir($self->datadir);
   my $r = $fc->unzip($output);

   return $r.'/'.$file;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->datadir.'/'.$self->input;
   if (! -f $input) {
      return $self->log->error("load: file [$input] not found");
   }

   $self->first_line_is_header(0);
   my $data = $self->read($input)
      or return $self->log->error("load: read failed");

   return $self->_load($data);
}

sub from_ipv4 {
   my $self = shift;
   my ($ipv4) = @_;

   if (! defined($ipv4)) {
      return $self->log->error($self->brik_help_run('from_ipv4'));
   }
   if (! defined($self->_load)) {
      return $self->log->error($self->brik_help_run('load'));
   }

   # Example:
   # [
   #   ["1.0.0.0", "1.0.0.255", 16777216, 16777471, "AU", "Australia"],
   #   ...
   # ]

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   my $prev = $self->log->level;
   $self->log->level(0);
   for my $line (@{$self->_load}) {
      my $subnet_list = $na->range_to_cidr($line->[0], $line->[1]);
      for my $subnet (@$subnet_list) {
         if ($na->match($ipv4, $subnet)) {
            $self->log->level($prev);
            return {
               subnet => $subnet,
               ipv4 => $ipv4,
               ipv4_first => $line->[0],
               ipv4_last => $line->[1],
               cc => $line->[4],
               country => $line->[5],
            };
         }
      }
   }

   $self->log->level($prev);
   $self->log->info("from_ipv4: no match found");

   return 0;
}

sub from_ipv6 {
   my $self = shift;
   my ($ipv6) = @_;

   $self->log->info("from_ipv6: TODO");

   return 0;
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
