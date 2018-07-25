#
# $Id$
#
# api::onyphe Brik
#
package Metabrik::Api::Onyphe;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         apikey => [ qw(key) ],
         apiurl => [ qw(url) ],
         wait => [ qw(seconds) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api',
         wait => 3,
      },
      commands => {
        api => [ qw(api ip apikey|OPTIONAL) ],
        ip => [ qw(ip apikey|OPTIONAL) ],
        geoloc => [ qw(ip) ],
        pastries => [ qw(ip apikey|OPTIONAL) ],
        inetnum => [ qw(ip apikey|OPTIONAL) ],
        threatlist => [ qw(ip apikey|OPTIONAL) ],
        synscan => [ qw(ip apikey|OPTIONAL) ],
        datascan => [ qw(ip|string apikey|OPTIONAL) ],
        onionscan => [ qw(ip|string apikey|OPTIONAL) ],
        sniffer => [ qw(ip apikey|OPTIONAL) ],
        reverse => [ qw(ip apikey|OPTIONAL) ],
        forward => [ qw(ip apikey|OPTIONAL) ],
        md5 => [ qw(sum apikey|OPTIONAL) ],
        list_ports => [ qw(since apikey|OPTIONAL)],
        search_datascan => [ qw(query apikey|OPTIONAL) ],
        search_inetnum => [ qw(query apikey|OPTIONAL) ],
        search_pastries => [ qw(query apikey|OPTIONAL) ],
        search_resolver => [ qw(query apikey|OPTIONAL) ],
        search_synscan => [ qw(query apikey|OPTIONAL) ],
        search_threatlist => [ qw(query apikey|OPTIONAL) ],
        search_onionscan => [ qw(query apikey|OPTIONAL) ],
        search_sniffer => [ qw(query apikey|OPTIONAL) ],
        user => [ qw(apikey|OPTIONAL) ],
      },
   };
}

sub api {
   my $self = shift;
   my ($api, $arg, $apikey, $page) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('api', $api) or return;
   $self->brik_help_run_undef_arg('api', $arg) or return;
   my $ref = $self->brik_help_run_invalid_arg('api', $arg, 'SCALAR', 'ARRAY') or return;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;

   my $wait = $self->wait;

   $api =~ s{_}{/}g;

   my $apiurl = $self->apiurl;
   $apiurl =~ s{/*$}{};

   $self->log->verbose("api: using url[$apiurl]");

   my @r = ();
   if ($ref eq 'ARRAY') {
      for my $this (@$arg) {
         my $res = $self->api($api, $this, $apikey, $page) or next;
         push @r, @$res;
      }
   }
   else {
   RETRY:
      my $url = $apiurl.'/'.$api.'/'.$arg.'?k='.$apikey;
      if (defined($page)) {
         $url .= '&page='.$page;
      }

      my $res = $self->get($url);
      my $code = $self->code;
      if ($code == 429) {
         $self->log->info("api: request limit reached, waiting before retry");
         sleep($wait);
         goto RETRY;
      }
      elsif ($code == 200) {
         my $content = $self->content;
         $content->{arg} = $arg;  # Add the IP or other info,
                                  # in case an ARRAY was requested.
         push @r, $content;
      }
      else {
         my $content = $self->get_last->content;
         $self->log->error("api: skipping from error [$content]");
      }
   }

   return \@r;
}

sub geoloc {
   my $self = shift;
   my ($ip) = @_;

   return $self->api('geoloc', $ip);
}

sub ip {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('ip', $ip, $apikey);
}

sub pastries {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('pastries', $ip, $apikey);
}

sub inetnum {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('inetnum', $ip, $apikey);
}

sub threatlist {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('threatlist', $ip, $apikey);
}

sub synscan {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('synscan', $ip, $apikey);
}

sub datascan {
   my $self = shift;
   my ($ip_or_string, $apikey, $page) = @_;

   return $self->api('datascan', $ip_or_string, $apikey, $page);
}

sub onionscan {
   my $self = shift;
   my ($onion, $apikey, $page) = @_;

   return $self->api('onionscan', $onion, $apikey, $page);
}

sub sniffer {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('sniffer', $ip, $apikey, $page);
}

sub reverse {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('reverse', $ip, $apikey);
}

sub forward {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('forward', $ip, $apikey);
}

sub md5 {
   my $self = shift;
   my ($sum, $apikey) = @_;

   return $self->api('md5', $sum, $apikey);
}

sub list_ports {
   my $self = shift;
   my ($apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('list_ports', $apikey) or return;

   my $wait = $self->wait;

   my $apiurl = $self->apiurl;
   $apiurl =~ s{/*$}{};

   my @r = ();

RETRY:
   my $res = $self->get($apiurl.'/list/ports/?k='.$apikey);
   my $code = $self->code;
   if ($code == 429) {
      $self->log->info("list_ports: request limit reached, waiting before retry");
      sleep($wait);
      goto RETRY;
   }
   elsif ($code == 200) {
      my $content = $self->content;
      push @r, $content;
   }

   return \@r;
}

sub search_datascan {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_datascan', $query, $apikey);
}

sub search_inetnum {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_inetnum', $query, $apikey);
}

sub search_pastries {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_pastries', $query, $apikey);
}

sub search_resolver {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_resolver', $query, $apikey);
}

sub search_synscan {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_synscan', $query, $apikey);
}

sub search_threatlist {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_threatlist', $query, $apikey);
}

sub search_onionscan {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_onionscan', $query, $apikey);
}

sub search_sniffer {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search_sniffer', $query, $apikey);
}

sub user {
   my $self = shift;
   my ($apikey) = @_;

   return $self->api('user', '', $apikey);
}

1;

__END__

=head1 NAME

Metabrik::Api::Onyphe - api::onyphe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
