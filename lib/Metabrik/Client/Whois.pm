#
# $Id$
#
# client::whois Brik
#
package Metabrik::Client::Whois;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable client whois) ],
      commands => {
         domain => [ qw(domain) ],
         available => [ qw(domain) ],
         expire => [ qw(domain) ],
         abuse => [ qw(domain) ],
      },
      require_modules => {
         'Metabrik::Network::Whois' => [ ],
      },
   };
}

sub domain {
   my $self = shift;
   my ($domain) = @_;

   if (! defined($domain)) {
      return $self->log->error($self->brik_help_run('domain'));
   }

   my $nw = Metabrik::Network::Whois->new_from_brik($self) or return;
   my $lines = $nw->domain($domain)
      or return $self->log->error("domain: domain failed");

   my %general = ();
   my %registrant = ();
   my %admin = ();
   my %tech = ();
   for my $line (@$lines) {
      next if (! length($line));
      #next if ($line =~ /^\s*#/);
      #next if ($line =~ /^\s*Access to Public Interest Registry WHOIS information/i);

      my ($k, $v) = $line =~ /^\s*(.*?)\s*:\s*(.*$)\s*$/;

      next if (! defined($k));

      # 4 categories: general, registrant, admin, tech
      if ($k =~ /domain name/i || $k =~ /domain$/i) {
         $general{domain} = lc($v);
      }
      elsif ($k =~ /domain id/i) {
         $general{domain_id} = $v;
      }
      elsif ($k =~ /creation date/i || $k =~ /created/) {
         $general{date_creation} = $v;
      }
      elsif ($k =~ /updated date/i || $k =~ /last.update/) {
         $general{date_updated} = $v;
      }
      elsif ($k =~ /registry expiry date/i || $k =~ /expiration date/i) {
         $general{date_expire} = $v;
      }
      elsif ($k =~ /sponsoring registrar iana id/i) {
         $general{sponsoring_registrar_iana_id} = $v;
      }
      elsif ($k =~ /sponsoring registrar$/i || $k =~ /^registrar$/) {
         $general{sponsoring_registrar} = $v;
      }
      elsif ($k =~ /dnssec/i) {
         $general{dnssec} = lc($v);
      }
      elsif ($k =~ /domain status/i) {
         exists($general{status}) ? ( $general{status} .= '|'.$v ) : ( $general{status} = $v);
      }
      elsif ($k =~ /^status/i) {
         if ($v eq 'ACTIVE') {
            $general{active} = 1;
         }
      }
      elsif ($k =~ /name server/i || $k =~ /nserver/) {
         next unless length($v);
         exists($general{nameserver}) ? ( $general{nameserver} .= '|'.lc($v) )
                                      : ( $general{nameserver} = lc($v));
      }
      elsif ($k =~ /registrant id/i || $k =~ /holder.c/) {
         $registrant{id} = $v;
      }
      elsif ($k =~ /registrant name/i) {
         $registrant{name} = $v;
      }
      elsif ($k =~ /registrant organization/i) {
         $registrant{organization} = $v;
      }
      elsif ($k =~ /registrant street/i) {
         $registrant{street} = $v;
      }
      elsif ($k =~ /registrant city/i) {
         $registrant{city} = $v;
      }
      elsif ($k =~ /registrant state\/province/i) {
         $registrant{state_province} = $v;
      }
      elsif ($k =~ /registrant postal code/i) {
         $registrant{postal_code} = $v;
      }
      elsif ($k =~ /registrant country/i) {
         $registrant{country_code} = $v;
      }
      elsif ($k =~ /registrant phone ext/i) {
         $registrant{phone_ext} = $v;
      }
      elsif ($k =~ /registrant phone$/i) {
         $registrant{phone} = $v;
      }
      elsif ($k =~ /registrant fax ext/i) {
         $registrant{fax_ext} = $v;
      }
      elsif ($k =~ /registrant fax$/i) {
         $registrant{fax} = $v;
      }
      elsif ($k =~ /registrant email/i) {
         $registrant{email} = $v;
      }
   }

   # Uniformisation time
   if (exists($general{status})) {
      $general{active} = 1;
   }

   return {
      raw => $lines,
      general => \%general,
      registrant => \%registrant,
   };
}

sub available {
   my $self = shift;
   my ($domain) = shift;

   if (! defined($domain)) {
      return $self->log->brik_help_run('available');
   }

   my $info = $self->domain($domain)
      or return $self->log->error("available: domain failed");

   return $info->{general}->{active} ? 0 : 1;
}

sub expire {
   my $self = shift;
   my ($domain) = shift;

   if (! defined($domain)) {
      return $self->log->brik_help_run('expire');
   }

   my $info = $self->domain($domain)
      or return $self->log->error("available: domain failed");

   return $info->{general}->{date_expire} || 'undef';
}

# Abuse if for IP addresses, we have to lookup the domain first.
sub abuse {
}

1;

__END__

=head1 NAME

Metabrik::Client::Whois - client::whois Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
