#
# $Id$
#
# api::virustotal Brik
#
package Metabrik::Api::Virustotal;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable rest api virustotal) ],
      attributes => {
         apikey => [ qw(apikey) ],
         output_mode => [ qw(json|xml) ],
      },
      attributes_default => {
         ssl_verify => 0,
         output_mode => 'json',
      },
      commands => {
         check_resource => [ qw(hash) ],
         file_report => [ qw(hash) ],
         ipv4_address_report => [ qw(ipv4_address) ],
         domain_report => [ qw(domain) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub check_resource {
   my $self = shift;
   my ($resource) = @_;

   my $apikey = $self->apikey;
   if (! defined($apikey)) {
      return $self->log->error($self->brik_help_set('apikey'));
   }
   if (! defined($resource)) {
      return $self->log->error($self->brik_help_run('check_resource'));
   }

   my $r = $self->post({ apikey => $apikey, resource => $resource },
      'https://www.virustotal.com/vtapi/v2/file/rescan')
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("check_resource: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

sub file_report {
   my $self = shift;
   my ($resource) = @_;

   my $apikey = $self->apikey;
   if (! defined($apikey)) {
      return $self->log->error($self->brik_help_set('apikey'));
   }
   if (! defined($resource)) {
      return $self->log->error($self->brik_help_run('file_report'));
   }

   my $r = $self->post({ apikey => $apikey, resource => $resource },
      'https://www.virustotal.com/vtapi/v2/file/report')
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("file_report: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

sub ipv4_address_report {
   my $self = shift;
   my ($ipv4_address) = @_;

   my $apikey = $self->apikey;
   if (! defined($apikey)) {
      return $self->log->error($self->brik_help_set('apikey'));
   }
   if (! defined($ipv4_address)) {
      return $self->log->error($self->brik_help_run('ipv4_address_report'));
   }

   my $r = $self->get('https://www.virustotal.com/vtapi/v2/ip-address/report?apikey='
      .$apikey.'&ip='.$ipv4_address)
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("ipv4_address_report: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

sub domain_report {
   my $self = shift;
   my ($domain) = @_;

   my $apikey = $self->apikey;
   if (! defined($apikey)) {
      return $self->log->error($self->brik_help_set('apikey'));
   }
   if (! defined($domain)) {
      return $self->log->error($self->brik_help_run('domain_report'));
   }

   my $r = $self->get('https://www.virustotal.com/vtapi/v2/domain/report?apikey='
      .$apikey.'&domain='.$domain)
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("domain_report: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

1;

__END__

=head1 NAME

Metabrik::Api::Virustotal - api::virustotal Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
