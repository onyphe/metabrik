#
# $Id$
#
# api::splunk Brik
#
package Metabrik::Api::Splunk;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

# API reference: http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTprolog

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable rest) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         output_mode => [ qw(json|xml) ],
         max_count => [ qw(max_count) ],
      },
      attributes_default => {
         uri => 'https://localhost:8089',
         username => 'admin',
         ssl_verify => 0,
         output_mode => 'xml',
         max_count => 10_000,
      },
      commands => {
         apps_local => [ qw(uri|OPTIONAL) ],
         search_jobs => [ qw(search uri|OPTIONAL) ],
         check_search_jobs_status => [ qw(sid uri|OPTIONAL) ],
         get_search_jobs_content => [ qw(sid uri|OPTIONAL) ],
         licenser_groups => [ qw(uri|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub apps_local {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('apps_local', $uri) or return;

   my $resp = $self->get($uri.'/services/apps/local') or return;

   my $content = $resp->{content};
   my $code = $resp->{code};

   $self->log->verbose("apps_local: returned code [$code]");

   my $sj = Metabrik::String::Xml->new_from_brik_init($self) or return;
   return $sj->decode($content);
}

sub search_jobs {
   my $self = shift;
   my ($search, $uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('search_jobs', $search) or return;
   $self->brik_help_run_undef_arg('search_jobs', $uri) or return;

   my $resp = $self->post({ search => $search }, $uri.'/services/search/jobs') or return;

   my $content = $resp->{content};
   my $code = $resp->{code};

   $self->log->verbose("search_jobs: returned code [$code]");

   my $sj = Metabrik::String::Xml->new_from_brik_init($self) or return;
   my $h = $sj->decode($content) or return;

   return $h->{sid};
}

sub check_search_jobs_status {
   my $self = shift;
   my ($sid, $uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('check_search_jobs_status', $sid) or return;
   $self->brik_help_run_undef_arg('check_search_jobs_status', $uri) or return;

   my $resp = $self->get($uri.'/services/search/jobs/'.$sid) or return;

   my $content = $resp->{content};
   my $code = $resp->{code};

   $self->log->verbose("check_search_jobs_status: returned code [$code]");

   my $sj = Metabrik::String::Xml->new_from_brik_init($self) or return;
   my $h = $sj->decode($content) or return;

   return $h->{content}{'s:dict'}{'s:key'}{dispatchState}{content};
}

sub get_search_jobs_content {
   my $self = shift;
   my ($sid, $uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('get_search_jobs_content', $sid) or return;
   $self->brik_help_run_undef_arg('get_search_jobs_content', $uri) or return;

   my $resp = $self->get($uri.'/services/search/jobs/'.$sid.'/results/?output_mode=csv')
      or return;

   my $content = $resp->{content};
   my $code = $resp->{code};

   $self->log->verbose("get_search_jobs_content: returned code [$code]");

   # Will return CSV data
   return $content;
}

sub licenser_groups {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('licenser_groups', $uri) or return;

   my $resp = $self->get($uri.'/services/licenser/groups') or return;

   my $content = $resp->{content};
   my $code = $resp->{code};

   $self->log->verbose("licenser_groups: returned code [$code]");

   my $sj = Metabrik::String::Xml->new_from_brik_init($self) or return;
   return $sj->decode($content);
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
