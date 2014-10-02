#
# $Id$
#
# audit::dns Brik
#
package Metabrik::Brik::Audit::Dns;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      nameserver => [],
      domainname => [],
   };
}

sub require_modules {
   return {
      'Net::DNS::Resolver' => [],
   };
}

sub help {
   return {
      'set:nameserver' => '<ip>',
      'set:domainname' => '<string>',
      'run:version' => '',
      'run:recursion' => '',
      'run:axfr' => '',
      'run:all' => '',
   };
}

sub version {
   my $self = shift;

   if (! defined($self->nameserver)) {
      return $self->log->info($self->help_set('nameserver'));
   }

   my $nameserver = $self->nameserver;

   my $dns = Net::DNS::Resolver->new(
      nameservers => [ $nameserver, ],
      recurse     => 0,
      searchlist  => [],
      debug       => $self->debug,
   ) or return $self->log->error("Net::DNS::Resolver: new");

   my $version = 'UNKNOWN';
   my $res = $dns->send('version.bind', 'TXT', 'CH');
   if (defined($res) && defined($res->{answer})) {
      my $rr = $res->{answer}->[0];
      if (defined($rr) && defined($rr->{rdata})) {
         $version = unpack("H*", $rr->{rdata});
      }
   }

   return {
      dns_version_bind => $version,
   };
}

sub recursion {
   my $self = shift;

   if (! defined($self->nameserver)) {
      return $self->log->info($self->help_set('nameserver'));
   }

   my $nameserver = $self->nameserver;

   my $dns = Net::DNS::Resolver->new(
      nameservers => [ $nameserver, ],
      recurse     => 1,
      searchlist  => [],
      debug       => $self->debug,
   ) or return $self->log->error("Net::DNS::Resolver: new");

   my $recursion_allowed = 0;
   my $res = $dns->search('example.com');
   if (defined($res) && defined($res->answer)) {
      $recursion_allowed = 1;
   }

   return {
      dns_recursion_allowed => $recursion_allowed,
   };
}

sub axfr {
   my $self = shift;

   if (! defined($self->nameserver)) {
      return $self->log->info($self->help_set('nameserver'));
   }

   if (! defined($self->domainname)) {
      return $self->log->info($self->help_set('domainname'));
   }

   my $nameserver = $self->nameserver;
   my $domainname = $self->domainname;

   my $dns = Net::DNS::Resolver->new(
      nameservers => [ $nameserver, ],
      recurse     => 0,
      searchlist  => [ $domainname, ],
      debug       => $self->debug,
   ) or return $self->log->error("Net::DNS::Resolver: new");

   my $axfr_allowed = 0;
   my @res = $dns->axfr;
   if (@res) {
      $axfr_allowed = 1;
   }

   return {
      dns_axfr_allowed => $axfr_allowed,
   };
}

sub all {
   my $self = shift;

   my $hash = {};

   my $version = $self->version;
   for (keys %$version) { $hash->{$_} = $version->{$_} }
   my $recursion = $self->recursion;
   for (keys %$recursion) { $hash->{$_} = $recursion->{$_} }
   my $axfr = $self->axfr;
   for (keys %$axfr) { $hash->{$_} = $axfr->{$_} }

   return $hash;
}

1;

__END__
