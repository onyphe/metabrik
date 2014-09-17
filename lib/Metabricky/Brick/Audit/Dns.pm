#
# $Id$
#
# Audit DNS brick
#
package Metabricky::Brick::Audit::Dns;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   nameserver
   domainname
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub require_modules {
   return [
      'Net::DNS::Resolver',
   ];
}

sub help {
   return [
      'set audit::dns nameserver <ip>',
      'set audit::dns domainname <string>',
      'run audit::dns version',
      'run audit::dns recursion',
      'run audit::dns axfr',
      'run audit::dns all',
   ];
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   # Do your init here

   return $self;
}

sub version {
   my $self = shift;

   if (! defined($self->nameserver)) {
      return $self->log->info("set audit::dns nameserver <ip>");
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

   print "dns_version_bind: $version\n";

   return $version;
}

sub recursion {
   my $self = shift;

   if (! defined($self->nameserver)) {
      return $self->log->info("set audit::dns nameserver <ip>");
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

   print "dns_recursion_allowed: $recursion_allowed\n";

   return $recursion_allowed;
}

sub axfr {
   my $self = shift;

   if (! defined($self->nameserver)) {
      return $self->log->info("set audit::dns nameserver <ip>");
   }

   if (! defined($self->domainname)) {
      return $self->log->info("set audit::dns domainname <string>");
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

   print "dns_axfr_allowed: $axfr_allowed\n";

   return $axfr_allowed;
}

sub all {
   my $self = shift;

   $self->version;
   $self->recursion;
   $self->axfr;

   return 1;
}

1;

__END__
