#
# $Id$
#
# api::splunk Brik
#
package Metabrik::Api::Splunk;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable rest) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],  # Inherited
         username => [ qw(username) ],  # Inherited
         password => [ qw(password) ],  # Inherited
         ssl_verify => [ qw(0|1) ], # Inherited
         output_mode => [ qw(json|xml) ],
         count => [ qw(number) ],
         offset => [ qw(number) ],
      },
      attributes_default => {
         uri => 'https://localhost:8089',
         username => 'admin',
         ssl_verify => 0,
         output_mode => 'xml',
         count => 1000,  # 0 means return everything
         offset => 0,  # 0 means return everything
      },
      commands => {
         reset_user_agent => [ ],  # Inherited
         apps_local => [ ],
         search_jobs => [ qw(search) ],
         search_jobs_sid => [ qw(sid) ],
         search_jobs_sid_results => [ qw(sid count|OPTIONAL offset|OPTIONAL) ],
         licenser_groups => [ ],
      },
   };
}

#
# API reference: 
# http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTlist
#

sub apps_local {
   my $self = shift;

   my $uri = $self->uri;
   $self->brik_help_set_undef_arg('apps_local', $uri) or return;

   $self->get($uri.'/services/apps/local') or return;

   my $content = $self->content or return;
   my $code = $self->code or return;

   $self->log->verbose("apps_local: returned code [$code]");
   $self->debug && $self->log->debug("apps_local: content [$content]");

   return $content;
}

#
# Example:
# run api::splunk search_jobs "{ search => 'search index=main' }" https://localhost:8089
#
sub search_jobs {
   my $self = shift;
   my ($post) = @_;

   my $uri = $self->uri;
   $self->brik_help_set_undef_arg('search_jobs', $uri) or return;
   $self->brik_help_run_undef_arg('search_jobs', $post) or return;
   $self->brik_help_run_invalid_arg('search_jobs', $post, 'HASH') or return;

   my $resp = $self->post($post, $uri.'/services/search/jobs') or return;

   my $code = $self->code;

   $self->log->verbose("search_jobs: returned code [$code]");
   $self->debug && $self->log->debug("search_jobs: content [".$resp->{content}."]");

   if ($code == 201) {  # Job created
      return $self->content;
   }

   return $self->log->error("search_jobs: failed with code [$code]");
}

sub search_jobs_sid {
   my $self = shift;
   my ($sid) = @_;

   my $uri = $self->uri;
   $self->brik_help_set_undef_arg('search_jobs_sid', $uri) or return;
   $self->brik_help_run_undef_arg('search_jobs_sid', $sid) or return;

   my $resp = $self->get($uri.'/services/search/jobs/'.$sid) or return;

   my $code = $self->code;

   $self->log->verbose("search_jobs_sid: returned code [$code]");
   $self->debug && $self->log->debug("search_jobs_sid: content [".$resp->{content}."]");

   if ($code == 404) {
      return 0;
   }
   elsif ($code == 200) {
      return $self->content;
   }

   return $self->log->error("search_jobs_sid: failed with code [$code]");
}

#
# http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTsearch#search.2Fjobs.2F.7Bsearch_id.7D.2Fresults
#
sub search_jobs_sid_results {
   my $self = shift;
   my ($sid, $count, $offset) = @_;

   my $uri = $self->uri;
   $count ||= $self->count;
   $offset ||= $self->offset;
   $self->brik_help_set_undef_arg('search_jobs_sid_results', $uri) or return;
   $self->brik_help_run_undef_arg('search_jobs_sid_results', $sid) or return;

   my $resp = $self->get(
      $uri.'/services/search/jobs/'.$sid.
      "/results/?output_mode=csv&offset=$offset&count=$count"
   ) or return;

   my $code = $self->code;

   $self->log->verbose("search_jobs_sid_results: returned code [$code]");
   $self->debug && $self->log->debug("search_jobs_sid_results: content [".$resp->{content}."]");

   if ($code == 200) {  # Job finished
      return $resp->{content}; # Return CSV content
   }
   elsif ($code == 204) {  # Job not finished
      return $self->log->error("search_jobs_sid_results: job not done");
   }

   return $self->log->error("search_jobs_sid_results: failed with code [$code]");
}

sub licenser_groups {
   my $self = shift;

   my $uri = $self->uri;
   $self->brik_help_set_undef_arg('licenser_groups', $uri) or return;

   my $resp = $self->get($uri.'/services/licenser/groups') or return;

   my $code = $self->code;

   $self->log->verbose("licenser_groups: returned code [$code]");
   $self->debug && $self->log->debug("licenser_groups: content [".$resp->{content}."]");

   return $self->content;
}

1;

__END__

=head1 NAME

Metabrik::Api::Splunk - api::splunk Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
