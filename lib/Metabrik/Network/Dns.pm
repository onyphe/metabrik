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
      tags => [ qw(unstable ns nameserver) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         nameserver => [ qw(ip_address|$ip_address_list) ],
         port => [ qw(port) ],
         use_recursion => [ qw(0|1) ],
         try => [ qw(try_number) ],
         rtimeout => [ qw(timeout) ],
      },
      attributes_default => {
         use_recursion => 0,
         port => 53,
         try => 3,
         rtimeout => 2,
      },
      commands => {
         lookup => [ qw(hostname|ip_address type nameserver|OPTIONAL port|OPTIONAL) ],
         version_bind => [ qw(hostname|ip_address) ],
      },
      require_modules => {
         'Net::DNS::Resolver' => [ ],
      },
   };
}

sub lookup {
   my $self = shift;
   my ($host, $type, $nameserver, $port) = @_;

   $type ||= 'A';
   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   if (! defined($host)) {
      return $self->log->error($self->brik_help_run('lookup'));
   }
   if (! defined($nameserver)) {
      return $self->log->error($self->brik_help_run('lookup'));
   }
   if (ref($nameserver) ne '' && ref($nameserver) ne 'ARRAY') {
      return $self->log->error("lookup: invalid value for nameserver [$nameserver]");
   }

   my $timeout = $self->rtimeout;

   my %args = (
      recurse => $self->use_recursion,
      searchlist => [],
      debug => $self->debug ? 1 : 0,
      tcp_timeout => $timeout,
      udp_timeout => $timeout,
      port => $port,
      persistent_udp => 1,
   );

   if (ref($nameserver) eq 'ARRAY') {
      $args{nameservers} = $nameserver;
   }
   else {
      $args{nameservers} = [ $nameserver ];
   }

   my $dns = Net::DNS::Resolver->new(%args);
   if (! defined($dns)) {
      return $self->log->error("lookup: Net::DNS::Resolver new failed");
   }

   $self->log->verbose("lookup: host [$host] for type [$type]");

   my $try = $self->try;
   my $packet;
   for (1..$try) {
      $packet = $dns->send($host, $type);
      if (defined($packet)) {
         last;
      }
      sleep(1);
   }

   if (! defined($packet)) {
      return $self->log->error("lookup: query failed [".$dns->errorstring."]");
   }

   $self->debug && $self->log->debug("lookup: ".$packet->string);

   my @res = ();
   my @answers = $packet->answer;
   for my $rr (@answers) {
      $self->debug && $self->log->debug("lookup: ".$rr->string);

      my $h = {
         type => $rr->type,
         ttl => $rr->ttl,
         name => $rr->name,
         string => $rr->string,
         raw => $rr,
      };
      if ($rr->can('address')) {
         $h->{address} = $rr->address;
      }
      if ($rr->can('cname')) {
         $h->{cname} = $rr->cname;
      }
      if ($rr->can('exchange')) {
         $h->{exchange} = $rr->exchange;
      }
      if ($rr->can('nsdname')) {
         $h->{nsdname} = $rr->nsdname;
      }
      if ($rr->can('ptrdname')) {
         $h->{ptrdname} = $rr->ptrdname;
      }
      if ($rr->can('rdatastr')) {
         $h->{rdatastr} = $rr->rdatastr;
      }
      if ($rr->can('dummy')) {
         $h->{dummy} = $rr->dummy;
      }
      if ($rr->can('target')) {
         $h->{target} = $rr->target;
      }

      push @res, $h;
   }

   return \@res;
}

sub version_bind {
   my $self = shift;
   my ($nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   if (! defined($nameserver)) {
      return $self->log->error($self->log->brik_help_run('version_bind'));
   }

   my $timeout = $self->rtimeout;

   my $dns = Net::DNS::Resolver->new(
      nameservers => [ $nameserver, ],
      recurse => $self->use_recursion,
      searchlist => [],
      tcp_timeout => $timeout,
      udp_timeout => $timeout,
      port => $port,
      debug => $self->debug ? 1 : 0,
   ); 
   if (! defined($dns)) {
      return $self->log->error("version_bind: Net::DNS::Resolver new failed");
   }

   my $version = 0;
   my $res = $dns->send('version.bind', 'TXT', 'CH');
   if (defined($res) && exists($res->{answer})) {
      my $rr = $res->{answer}->[0];
      if (defined($rr) && exists($rr->{rdata})) {
         $version = unpack('H*', $rr->{rdata});
      }
   }

   $self->log->verbose("version_bind: version [$version]");

   return $version;
}

1;

__END__

=head1 NAME

Metabrik::Network::Dns - network::dns Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
