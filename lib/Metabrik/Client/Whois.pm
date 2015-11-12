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
         ip => [ qw(ip_address) ],
         domain => [ qw(domain) ],
         is_available_domain => [ qw(domain) ],
      },
      require_modules => {
         'Metabrik::Network::Address' => [ ],
         'Metabrik::Network::Whois' => [ ],
         'Metabrik::String::Parse' => [ ],
      },
   };
}

sub _parse_whois {
   my $self = shift;
   my ($lines) = @_;

   my $sp = Metabrik::String::Parse->new_from_brik_init($self) or return;
   my $chunks = $sp->split_by_blank_line($lines) or return;

   my @chunks = ();
   for my $this (@$chunks) {
      my $new = {};
      my $abuse = '';
      for (@$this) {
         # If an abuse email adress can be found, we gather it.
         if (/abuse/i && /\@/) {
            ($abuse) = $_ =~ /^.*\s(\S+\@\S+)\s?.*$/;
            $abuse =~ s/['"]//g;
         }

         next if (/^\s*%/);  # Skip comments

         # We default to split by the first encountered : char
         if (/^\s*([^:]+?)\s*:\s*(.*)\s*$/) {
            if (defined($1) && defined($2)) {
               my $k = lc($1);
               my $v = $2;
               $k =~ s{[ /]}{_}g;
               if (exists($new->{$k})) {
                  $new->{$k} .= "\n$v";
               }
               else {
                  $new->{$k} = $v;
               }
            }
         }
      }

      # If we found some email address along with 'abuse' string, we add this email address
      if (length($abuse)) {
         $new->{abuse} = $abuse;
      }

      if (keys %$new > 0) {
         push @chunks, $new;
      }
   }

   return \@chunks;
}

sub ip {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      return $self->log->error($self->brik_help_run('ip'));
   }

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if (! $na->is_ip($ip)) {
      return $self->log->error("ip: not a valid IP address [$ip]");
   }

   my $nw = Metabrik::Network::Whois->new_from_brik($self) or return;
   my $lines = $nw->target($ip) or return;

   my $chunks = $self->_parse_whois($lines);

   my $r = { raw => $lines };

   for (@$chunks) {
      if (exists($_->{abuse})) {
         exists($r->{abuse}) ? ($r->{abuse} .= "\n".$_->{abuse})
                             : ($r->{abuse} = $_->{abuse});
      }
      if (exists($_->{inetnum})) {
         exists($r->{inetnum}) ? ($r->{inetnum} .= "\n".$_->{inetnum})
                               : ($r->{inetnum} = $_->{inetnum});
      }
      if (exists($_->{descr})) {
         exists($r->{descr}) ? ($r->{descr} .= "\n".$_->{descr})
                             : ($r->{descr} = $_->{descr});
      }
      if (exists($_->{source})) {
         exists($r->{source}) ? ($r->{source} .= "\n".$r->{source})
                              : ($r->{source} = $_->{source});
      }
      if (exists($_->{netname})) {
         exists($r->{netname}) ? ($r->{netname} .= "\n".$r->{netname})
                               : ($r->{netname} = $_->{netname});
      }
      if (exists($_->{org})) {
         exists($r->{org}) ? ($r->{org} .= "\n".$r->{org})
                           : ($r->{org} = $_->{org});
      }
      if (exists($_->{country})) {
         exists($r->{country}) ? ($r->{country} .= "\n".$r->{country})
                               : ($r->{country} = $_->{country});
      }
      if (exists($_->{"org-name"})) {
         exists($r->{"org-name"}) ? ($r->{"org-name"} .= "\n".$r->{"org-name"})
                                  : ($r->{"org-name"} = $_->{"org-name"});
      }
      if (exists($_->{origin})) {
         exists($r->{origin}) ? ($r->{origin} .= "\n".$r->{origin})
                              : ($r->{origin} = $_->{origin});
      }
      if (exists($_->{route})) {
         exists($r->{route}) ? ($r->{route} .= "\n".$r->{route})
                             : ($r->{route} = $_->{route});
      }
   }

   # Dedups lines
   for (keys %$r) {
      next if $_ eq 'raw';
      if (my @toks = split(/\n/, $r->{$_})) {
         my %uniq = map { $_ => 1 } @toks;
         $r->{$_} = join("\n", sort { $a cmp $b } keys %uniq);  # With a sort
      }
   }

   return $r;
}

sub domain {
   my $self = shift;
   my ($domain) = @_;

   if (! defined($domain)) {
      return $self->log->error($self->brik_help_run('domain'));
   }

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if ($na->is_ip($domain)) {
      return $self->log->error("domain: domain [$domain] must not be an IP address");
   }

   my $nw = Metabrik::Network::Whois->new_from_brik($self) or return;
   my $lines = $nw->target($domain) or return;

   my $chunks = $self->_parse_whois($lines);

   my $r = { raw => $lines };

   # 4 categories: general, registrant, admin, tech
   for (@$chunks) {
      # Registrar,Sponsoring Registrar,
      if (exists($_->{registrar})) {
         exists($r->{registrar}) ? ($r->{registrar} .= "\n".$_->{registrar})
                                 : ($r->{registrar} = $_->{registrar});
      }
      if (exists($_->{registrar})) {
         exists($r->{registrar}) ? ($r->{registrar} .= "\n".$_->{sponsoring_registrar})
                                 : ($r->{registrar} = $_->{sponsoring_registrar});
      }
      # Whois Server,
      if (exists($_->{whois_server})) {
         exists($r->{whois_server}) ? ($r->{whois_server} .= "\n".$_->{whois_server})
                                    : ($r->{whois_server} = $_->{whois_server});
      }
      # Domain Name,
      if (exists($_->{domain_name})) {
         exists($r->{domain_name}) ? ($r->{domain_name} .= "\n".$_->{domain_name})
                                   : ($r->{domain_name} = $_->{domain_name});
      }
      # Creation Date,
      if (exists($_->{creation_date})) {
         exists($r->{creation_date}) ? ($r->{creation_date} .= "\n".$_->{creation_date})
                                     : ($r->{creation_date} = $_->{creation_date});
      }
      # Updated Date,
      if (exists($_->{updated_date})) {
         exists($r->{updated_date}) ? ($r->{updated_date} .= "\n".$_->{updated_date})
                                    : ($r->{updated_date} = $_->{updated_date});
      }
      # Registrar Registration Expiration Date,Expiration Date,Registry Expiry Date,
      if (exists($_->{registrar_registration_expiration_date})) {
         exists($r->{expiration_date}) ? ($r->{expiration_date} .= "\n".$_->{registrar_registration_expiration_date})
                                       : ($r->{expiration_date} = $_->{registrar_registration_expiration_date});
      }
      if (exists($_->{expiration_date})) {
         exists($r->{expiration_date}) ? ($r->{expiration_date} .= "\n".$_->{expiration_date})
                                       : ($r->{expiration_date} = $_->{expiration_date});
      }
      if (exists($_->{expiration_date})) {
         exists($r->{expiration_date}) ? ($r->{expiration_date} .= "\n".$_->{registry_expiry_date})
                                       : ($r->{expiration_date} = $_->{registry_expiry_date});
      }
      # Registrar URL,Referral URL,
      if (exists($_->{registrar_url})) {
         exists($r->{registrar_url}) ? ($r->{registrar_url} .= "\n".$_->{registrar_url})
                                     : ($r->{registrar_url} = $_->{registrar_url});
      }
      if (exists($_->{registrar_url})) {
         exists($r->{registrar_url}) ? ($r->{registrar_url} .= "\n".$_->{referral_url})
                                     : ($r->{registrar_url} = $_->{referral_url});
      }
      # DNSSEC,
      if (exists($_->{dnssec})) {
         exists($r->{dnssec}) ? ($r->{dnssec} .= "\n".$_->{dnssec})
                              : ($r->{dnssec} = $_->{dnssec});
      }
      # Domain Status,Status,
      if (exists($_->{domain_status})) {
         exists($r->{domain_status}) ? ($r->{domain_status} .= "\n".$_->{domain_status})
                                     : ($r->{domain_status} = $_->{domain_status});
      }
      if (exists($_->{domain_status})) {
         exists($r->{domain_status}) ? ($r->{domain_status} .= "\n".$_->{status})
                                     : ($r->{domain_status} = $_->{status});
      }
      # Name Server,
      if (exists($_->{name_server})) {
         exists($r->{name_server}) ? ($r->{name_server} .= "\n".$_->{name_server})
                                   : ($r->{name_server} = $_->{name_server});
      }
      # Registrant Name,
      if (exists($_->{registrant_name})) {
         exists($r->{registrant_name}) ? ($r->{registrant_name} .= "\n".$_->{registrant_name})
                                       : ($r->{registrant_name} = $_->{registrant_name});
      }
      # Registrant Organization,
      if (exists($_->{registrant_organization})) {
         exists($r->{registrant_organization}) ? ($r->{registrant_organization} .= "\n".$_->{registrant_organization})
                                               : ($r->{registrant_organization} = $_->{registrant_organization});
      }
      # Registrant Street,
      if (exists($_->{registrant_street})) {
         exists($r->{registrant_street}) ? ($r->{registrant_street} .= "\n".$_->{registrant_street})
                                         : ($r->{registrant_street} = $_->{registrant_street});
      }
      # Registrant City,
      if (exists($_->{registrant_city})) {
         exists($r->{registrant_city}) ? ($r->{registrant_city} .= "\n".$_->{registrant_city})
                                       : ($r->{registrant_city} = $_->{registrant_city});
      }
      # Registrant Postal Code,
      if (exists($_->{registrant_postal_code})) {
         exists($r->{registrant_postal_code}) ? ($r->{registrant_postal_code} .= "\n".$_->{registrant_postal_code})
                                              : ($r->{registrant_postal_code} = $_->{registrant_postal_code});
      }
      # Registrant State/Province,
      if (exists($_->{registrant_state_province})) {
         exists($r->{registrant_state_province}) ? ($r->{registrant_state_province} .= "\n".$_->{registrant_state_province})
                                                 : ($r->{registrant_state_province} = $_->{registrant_state_province});
      }
      # Registrant Country,
      if (exists($_->{registrant_country})) {
         exists($r->{registrant_country}) ? ($r->{registrant_country} .= "\n".$_->{registrant_country})
                                          : ($r->{registrant_country} = $_->{registrant_country});
      }
      # Registrant Email,
      if (exists($_->{registrant_email})) {
         exists($r->{registrant_email}) ? ($r->{registrant_email} .= "\n".$_->{registrant_email})
                                        : ($r->{registrant_email} = $_->{registrant_email});
      }
   }

   # If there is more than the raw key, domain exists
   if (keys %$r > 1) {
      $r->{domain_exists} = 1;
   }
   else {
      $r->{domain_exists} = 0;
   }

   return $r;
}

sub is_available_domain {
   my $self = shift;
   my ($domain) = shift;

   if (! defined($domain)) {
      return $self->log->brik_help_run('is_available');
   }

   my $info = $self->domain($domain) or return;

   return $info->{domain_exists};
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
