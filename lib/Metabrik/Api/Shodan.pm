#
# $Id$
#
# api::shodan Brik
#
package Metabrik::Api::Shodan;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

# API: https://developer.shodan.io/api

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable rest api shodan) ],
      attributes => {
         output_mode => [ qw(json|xml) ],
         apikey => [ qw(apikey) ],
         uri => [ qw(shodan_uri) ],
      },
      attributes_default => {
         output_mode => 'json',
         ssl_verify => 0,
         uri => 'https://api.shodan.io',
      },
      commands => {
         myip => [ ],
         api_info => [ ],
         host_ip => [ qw(ip_address) ],
      },
      require_modules => {
         'Metabrik::Network::Address' => [ ],
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub myip {
   my $self = shift;

   my $apikey = $self->apikey;
   if (! defined($apikey)) {
      return $self->log->error($self->brik_help_set('api_key'));
   }

   my $uri = $self->uri;

   my $resp = $self->get($uri.'/tools/myip?key='.$apikey) or return;
   my $content = $resp->{content};

   $content =~ s/"?//g;

   return $content;
}

sub api_info {
   my $self = shift;

   my $apikey = $self->apikey;
   if (! defined($apikey)) {
      return $self->log->error($self->brik_help_set('api_key'));
   }

   my $uri = $self->uri;

   my $resp = $self->get($uri.'/api-info?key='.$apikey) or return;
   my $content = $resp->{content};

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decoded = $sj->decode($content) or return;

   return $decoded;
}

sub host_ip {
   my $self = shift;
   my ($ip) = @_;

   my $apikey = $self->apikey;
   if (! defined($apikey)) {
      return $self->log->error($self->brik_help_set('api_key'));
   }
   if (! defined($ip)) {
      return $self->log->error($self->brik_help_run('host_ip'));
   }

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if (! $na->is_ip($ip)) {
      return $self->log->error("host_ip: invalid format for IP [$ip]");
   }

   my $uri = $self->uri;

   my $resp = $self->get($uri.'/shodan/host/'.$ip.'?key='.$apikey) or return;
   my $content = $resp->{content};

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decoded = $sj->decode($content) or return;

   return $decoded;
}

1;

__END__

=head1 NAME

Metabrik::Api::Shodan - api::shodan Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
