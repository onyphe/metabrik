#
# $Id$
#
# client::elasticsearch::query Brik
#
package Metabrik::Client::Elasticsearch::Query;
use strict;
use warnings;

use base qw(Metabrik::Client::Elasticsearch);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         index => [ qw(index) ],     # Inherited
         type => [ qw(type) ],       # Inherited
         client => [ qw(INTERNAL) ],
      },
      attributes_default => {
         index => '*',
         type => '*',
      },
      commands => {
         create_client => [ ],
         reset_client => [ ],
         get_query_result_total => [ qw($query_result) ],
         get_query_result_hits => [ qw($query_result) ],
         get_query_result_timed_out => [ qw($query_result) ],
         get_query_result_took => [ qw($query_result) ],
         term => [ qw(field value index|OPTIONAL type|OPTIONAL) ],
         range => [ qw(field_from field_to value index|OPTIONAL type|OPTIONAL) ],
         top => [ qw(field count index|OPTIONAL type|OPTIONAL) ],
         top_match => [ qw(field count field2 match index|OPTIONAL type|OPTIONAL) ],
      },
   };
}

sub create_client {
   my $self = shift;

   my $ce = $self->client;
   if (! defined($ce)) {
      $ce = $self->open or return;
      $self->client($ce);
   }

   return $ce;
}

sub reset_client {
   my $self = shift;

   return $self->log->info("TODO");
}

sub get_query_result_total {
   my $self = shift;
   my ($query_result) = @_;

   $self->brik_help_run_undef_arg('get_query_result_total', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_total', $query_result, 'HASH') or return;

   if (! exists($query_result->{hits})) {
      return $self->log->error("get_query_result_total: invalid query result, no hits found");
   }
   if (! exists($query_result->{hits}{total})) {
      return $self->log->error("get_query_result_total: invalid query result, no total found");
   }

   return $query_result->{hits}{total};
}

sub get_query_result_hits {
   my $self = shift;
   my ($query_result) = @_;

   $self->brik_help_run_undef_arg('get_query_result_hits', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_hits', $query_result, 'HASH') or return;

   if (! exists($query_result->{hits})) {
      return $self->log->error("get_query_result_hits: invalid query result, no hits found");
   }
   if (! exists($query_result->{hits}{hits})) {
      return $self->log->error("get_query_result_hits: invalid query result, no hits in hits found");
   }

   return $query_result->{hits}{hits};
}

sub get_query_result_timed_out {
   my $self = shift;
   my ($query_result) = @_;

   $self->brik_help_run_undef_arg('get_query_result_timed_out', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_timed_out', $query_result, 'HASH')
      or return;

   if (! exists($query_result->{timed_out})) {
      return $self->log->error("get_query_result_timed_out: invalid query result, ".
         "no timed_out found");
   }

   return $query_result->{timed_out} ? 1 : 0;
}

sub get_query_result_took {
   my $self = shift;
   my ($query_result) = @_;

   $self->brik_help_run_undef_arg('get_query_result_took', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_took', $query_result, 'HASH')
      or return;

   if (! exists($query_result->{took})) {
      return $self->log->error("get_query_result_took: invalid query result, no took found");
   }

   return $query_result->{took};
}

sub _query {
   my $self = shift;
   my ($q, $index, $type) = @_;

   my $r = $self->query($q, $index, $type) or return;
   if (defined($r)) {
      if (exists($r->{hits}{total})) {
         return $r;
      }
      else {
         return $self->log->error("_query: failed with [$r]");
      }
   }

   return $self->log->error("_query: failed");
}

#
# run client::elasticsearch::query term domain example.com index1-*,index2-*
#
sub term {
   my $self = shift;
   my ($field, $value, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('term', $field) or return;
   $self->brik_help_run_undef_arg('term', $value) or return;
   $self->brik_help_run_undef_arg('term', $index) or return;
   $self->brik_help_run_undef_arg('term', $type) or return;

   my $ce = $self->create_client or return;

   my $q = {
      query => {
         term => {
            $field => $value,
         },
      },
   };

   return $self->_query($q, $index, $type);
}

#
# run client::elasticsearch::query range ip_range.from ip_range.to 192.168.255.36
#
sub range {
   my $self = shift;
   my ($field_from, $field_to, $value, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('range', $field_from) or return;
   $self->brik_help_run_undef_arg('range', $field_to) or return;
   $self->brik_help_run_undef_arg('range', $value) or return;
   $self->brik_help_run_undef_arg('range', $index) or return;
   $self->brik_help_run_undef_arg('range', $type) or return;

   my $ce = $self->create_client or return;

   my $q = {
      query => {
         constant_score => {
            filter => {
               and => [
                  { range => { $field_to => { gte => $value } } },
                  { range => { $field_from => { lte => $value } } },
               ],
            },
         },
      },
   };

   return $self->_query($q, $index, $type);
}

#
# run client::elasticsearch::query top name 10 users-*
#
sub top {
   my $self = shift;
   my ($field, $count, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('top', $field) or return;
   $self->brik_help_run_undef_arg('top', $count) or return;
   $self->brik_help_run_undef_arg('top', $index) or return;
   $self->brik_help_run_undef_arg('top', $type) or return;

   my $ce = $self->create_client or return;

   my $q = {
      aggs => {
         top_values => {
            terms => {
               field => $field,
               size => int($count),
            },
         },
      },
   };

   return $self->_query($q, $index, $type);
}

sub top_match {
   my $self = shift;
   my ($field, $count, $field2, $match, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('top_match', $field) or return;
   $self->brik_help_run_undef_arg('top_match', $count) or return;
   $self->brik_help_run_undef_arg('top_match', $field2) or return;
   $self->brik_help_run_undef_arg('top_match', $match) or return;
   $self->brik_help_run_undef_arg('top_match', $index) or return;
   $self->brik_help_run_undef_arg('top_match', $type) or return;

   my $ce = $self->create_client or return;

   my $q = {
      query => {
         match => {
            $field2 => $match,
         },
      },
      aggs => {
         top_values => {
            terms => {
               field => $field,
               size => int($count),
            },
         },
      },
   };

   return $self->_query($q, $index, $type);
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch::Query - client::elasticsearch::query Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
