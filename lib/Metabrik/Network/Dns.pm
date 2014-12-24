#
# $Id$
#
# network::dns Brik
#
package Metabrik::Network::Dns;
use strict;
use warnings;

use base qw(Metabrik);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable dns nameserver) ],
      attributes => {
         nameserver => [ qw(ip_address) ],
         port => [ qw(port) ],
         use_recursion => [ qw(0|1) ],
         try => [ qw(try_number) ],
      },
      attributes_default => {
         nameserver => '8.8.4.4',
         port => 53,
         use_recursion => 0,
         try => 3,
      },
      commands => {
         lookup => [ qw(hostname|ip_address nameserver|OPTIONAL port|OPTIONAL) ],
         check_version => [ qw(hostname|ip_address) ],
      },
      require_modules => {
         'Net::DNS::Resolver' => [ ],
      },
   };
}

sub lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   if (! defined($host)) {
      return $self->log->error($self->brik_help_run('lookup'));
   }

   $nameserver ||= $self->nameserver;
   $port ||= $self->port;

   my $dns = Net::DNS::Resolver->new(
      nameservers => [ $nameserver, ],
      port => $port,
      recurse => $self->use_recursion,
      searchlist => [],
      debug => $self->debug ? 1 : 0,
      tcp_timeout => 5, #$self->global->rtimeout,
      udp_timeout => 5, #$self->global->rtimeout,
   );
   if (! defined($dns)) {
      return $self->log->error("lookup: Net::DNS::Resolver new failed");
   }

   my $try = $self->try;
   my $packet;
   for (1..$try) {
      $packet = $dns->search($host);
      if (defined($packet)) {
         last;
      }
   }

   if (! defined($packet)) {
      return $self->log->error("lookup: search failed");
   }

   $self->debug && $self->log->debug("lookup: ".$packet->string);

   my @res = ();
   my @answers = $packet->answer;
   for my $rr (@answers) {
      my $h = {
         name => $rr->name,
         type => $rr->type,
         raw => $rr,
      };
      if (defined($rr->address)) {
         $h->{address} = $rr->address;
      }
      push @res, $h;
   }

   return \@res;
}

sub check_version {
   my $self = shift;
   my ($nameserver) = @_;

   $nameserver ||= $self->nameserver;

   my $dns = Net::DNS::Resolver->new(
      nameservers => [ $nameserver, ],
      recurse => $self->use_recursion,
      searchlist => [],
      debug => $self->log->level,
   ); 
   if (! defined($dns)) {
      return $self->log->error("check_version: Net::DNS::Resolver new failed");
   }

   my $version = 0;
   my $res = $dns->send('version.bind', 'TXT', 'CH');
   if (defined($res) && exists($res->{answer})) {
      my $rr = $res->{answer}->[0];
      if (defined($rr) && exists($rr->{rdata})) {
         $version = unpack('H*', $rr->{rdata});
      }
   }

   $self->log->verbose("check_version: version [$version]");

   return {
      dns_version => $version,
   };
}

1;

__END__

=head1 NAME

Metabrik::Network::Dns - network::dns Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
