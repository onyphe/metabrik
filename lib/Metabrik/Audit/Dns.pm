#
# $Id$
#
# audit::dns Brik
#
package Metabrik::Audit::Dns;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable audit dns) ],
      attributes => {
         nameserver => [ qw(nameserver|$nameserver_list) ],
         domainname => [ qw(domainname) ],
         rtimeout => [ qw(timeout) ],
      },
      attributes_default => {
         rtimeout => 2,
         nameserver => '127.0.0.1',
      },
      commands => {
         version => [ qw(nameserver|$nameserver_list|OPTIONAL) ],
         recursion => [ qw(nameserver|$nameserver_list|OPTIONAL) ],
         axfr => [ qw(nameserver|$nameserver_list|OPTIONAL domainname|$domainname_list|OPTIONAL) ],
         all => [ qw(nameserver|$nameserver_list|OPTIONAL domainname|$domainname_list|OPTIONAL) ],
      },
      require_modules => {
         'Net::DNS::Resolver' => [ ],
      },
   };
}

sub version {
   my $self = shift;
   my ($nameserver) = @_;

   $nameserver ||= $self->nameserver;
   if (! defined($nameserver)) {
      return $self->log->error($self->brik_help_run('version'));
   }

   my $result = {};
   if (ref($nameserver) eq 'ARRAY') {
      for (@$nameserver) {
         my $r = $self->version($_);
         for (keys %$r) { $result->{$_} = $r->{$_} }
      }
   }
   else {
      my $dns = Net::DNS::Resolver->new(
         nameservers => [ $nameserver ],
         recurse => 0,
         searchlist => [],
         debug => $self->debug,
         udp_timeout => $self->rtimeout,
         tcp_timeout => $self->rtimeout,
      ) or return $self->log->error("version: Net::DNS::Resolver::new failed");
   
      my $version = 'undef';
      my $res = $dns->send('version.bind', 'TXT', 'CH');
      if (defined($res) && defined($res->{answer})) {
         my $rr = $res->{answer}->[0];
         if (defined($rr) && defined($rr->{rdata})) {
            $version = unpack("H*", $rr->{rdata});
         }
      }

      $result->{$nameserver} = $version;
   }

   return $result;
}

sub recursion {
   my $self = shift;
   my ($nameserver) = @_;

   $nameserver ||= $self->nameserver;
   if (! defined($nameserver)) {
      return $self->log->error($self->brik_help_run('recursion'));
   }

   my $result = {};
   if (ref($nameserver)) {
      for (@$nameserver) {
         my $r = $self->recursion($_);
         for (keys %$r) { $result->{$_} = $r->{$_} }
      }
   }
   else {
      my $dns = Net::DNS::Resolver->new(
         nameservers => [ $nameserver ],
         recurse => 1,
         searchlist => [],
         debug => $self->debug,
         udp_timeout => $self->rtimeout,
         tcp_timeout => $self->rtimeout,
      ) or return $self->log->error("recursion: Net::DNS::Resolver::new failed");

      my $recursion_allowed = 0;
      my $res = $dns->search('example.com');
      if (defined($res) && defined($res->answer)) {
         $recursion_allowed = 1;
      }

      $result->{$nameserver} = $recursion_allowed;
   }

   return $result;
}

sub axfr {
   my $self = shift;
   my ($nameserver, $domainname) = @_;

   $nameserver ||= $self->nameserver;
   $domainname ||= $self->domainname;
   if (! defined($nameserver)) {
      return $self->log->error($self->brik_help_run('nameserver'));
   }
   if (! defined($domainname)) {
      return $self->log->error($self->brik_help_run('nameserver'));
   }

   my $result = {};
   if (ref($nameserver) eq 'ARRAY') {
      for (@$nameserver) {
         my $r = $self->axfr($_);
         for (keys %$r) { $result->{$_} = $r->{$_} }
      }
   }
   else {
      my $dns = Net::DNS::Resolver->new(
         nameservers => [ $nameserver ],
         recurse => 0,
         searchlist => ref($domainname) eq 'ARRAY' ? $domainname : [ $domainname ],
         debug => $self->debug,
         udp_timeout => $self->rtimeout,
         tcp_timeout => $self->rtimeout,
      ) or return $self->log->error("axfr: Net::DNS::Resolver::new failed");

      my $axfr_allowed = 0;
      my @res = $dns->axfr;
      if (@res) {
         $axfr_allowed = 1;
      }

      $result->{$nameserver} = $axfr_allowed;
   }

   return $result;
}

sub all {
   my $self = shift;
   my ($nameserver, $domainname) = @_;

   my $result = {};

   my $version = $self->version($nameserver, $domainname);
   for (keys %$version) { $result->{$_}{version} = $version->{$_} }

   my $recursion = $self->recursion($nameserver, $domainname);
   for (keys %$recursion) { $result->{$_}{recursion} = $recursion->{$_} }

   my $axfr = $self->axfr($nameserver, $domainname);
   for (keys %$axfr) { $result->{$_}{axfr} = $axfr->{$_} }

   return $result;
}

1;

__END__

=head1 NAME

Metabrik::Audit::Dns - audit::dns Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
