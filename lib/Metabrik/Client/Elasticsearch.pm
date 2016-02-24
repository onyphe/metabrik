#
# $Id$
#
# client::elasticsearch Brik
#
package Metabrik::Client::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable elk) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         nodes => [ qw(node_list) ],
         cxn_pool => [ qw(Sniff|Static|Static::NoPing) ],
         date => [ qw(date) ],
         index => [ qw(index) ],
         type => [ qw(type) ],
         from => [ qw(number) ],
         size => [ qw(count) ],
         _elk => [ qw(INTERNAL) ],
         _bulk => [ qw(INTERNAL) ],
      },
      attributes_default => {
         nodes => [ qw(http://localhost:9200) ],
         cxn_pool => 'Sniff',
         from => 0,
         size => 10,
      },
      commands => {
         open => [ qw(nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         open_bulk_mode => [ qw(index|OPTIONAL type|OPTIONAL nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         index_document => [ qw(document index|OPTIONAL type|OPTIONAL) ],
         index_bulk => [ qw(document index|OPTIONAL type|OPTIONAL) ],
         query => [ qw($query_hash index|OPTIONAL) ],
         count => [ qw(index|OPTIONAL type|OPTIONAL) ],
         get_from_id => [ qw(id index|OPTIONAL type|OPTIONAL) ],
         www_search => [ qw(query index|OPTIONAL) ],
         delete_index => [ qw(index) ],
         show_indices => [ ],
         get_index => [ qw(index) ],
         get_mappings => [ qw(index) ],
         create_index => [ qw(index) ],
         create_index_with_mappings => [ qw(index mappings) ],
      },
      require_modules => {
         'Search::Elasticsearch' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($nodes, $cxn_pool) = @_;

   $nodes ||= $self->nodes;
   $cxn_pool ||= $self->cxn_pool;
   $self->brik_help_run_undef_arg('open', $nodes) or return;
   $self->brik_help_run_undef_arg('open', $cxn_pool) or return;
   $self->brik_help_run_invalid_arg('open', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('open', $nodes) or return;

   my $elk = Search::Elasticsearch->new(
      nodes => $nodes,
      cxn_pool => $cxn_pool,
   );
   if (! defined($elk)) {
      return $self->log->error("open: failed");
   }

   $self->_elk($elk);

   return $nodes;
}

sub open_bulk_mode {
   my $self = shift;
   my ($index, $type, $nodes, $cxn_pool) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $nodes ||= $self->nodes;
   $cxn_pool ||= $self->cxn_pool;
   $self->brik_help_run_undef_arg('open_bulk_mode', $index) or return;
   $self->brik_help_run_undef_arg('open_bulk_mode', $type) or return;
   $self->brik_help_run_undef_arg('open_bulk_mode', $nodes) or return;
   $self->brik_help_run_undef_arg('open_bulk_mode', $cxn_pool) or return;
   $self->brik_help_run_invalid_arg('open_bulk_mode', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('open_bulk_mode', $nodes) or return;

   $self->open($nodes, $cxn_pool) or return;

   my $elk = $self->_elk;

   my $bulk = $elk->bulk_helper(
      index => $index,
      type => $type,
   );
   if (! defined($bulk)) {
      return $self->log->error("open_bulk_mode: failed");
   }

   $self->_bulk($bulk);

   return $nodes;
}

sub index_document {
   my $self = shift;
   my ($doc, $index, $type) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('index_document', $index) or return;
   $self->brik_help_run_undef_arg('index_document', $type) or return;
   $self->brik_help_run_undef_arg('index_document', $doc) or return;
   $self->brik_help_run_invalid_arg('index_document', $doc, 'HASH') or return;

   my $r = $elk->index(
      index => $index,
      type => $type,
      body => $doc,
   );

   return $r;
}

sub index_bulk {
   my $self = shift;
   my ($doc, $index, $type) = @_;

   my $bulk = $self->_bulk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;
   $self->brik_help_run_undef_arg('index_bulk', $doc) or return;
   $self->brik_help_run_undef_arg('index_bulk', $index) or return;
   $self->brik_help_run_undef_arg('index_bulk', $type) or return;

   return $self->_bulk->index({ source => $doc });
}

sub count {
   my $self = shift;
   my ($index, $type) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('count', $index) or return;
   $self->brik_help_run_undef_arg('count', $type) or return;

   my $r = $elk->search(
      index => $index,
      type => $type,
      search_type => 'count',
      body => {
         query => {
            match_all => {},
         },
      },
   );

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/full-text-queries.html
#
sub query {
   my $self = shift;
   my ($query, $index) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('query', $query) or return;
   $self->brik_help_run_undef_arg('query', $index) or return;
   $self->brik_help_run_invalid_arg('query', $query, 'HASH') or return;

   my $r = $elk->search(
      index => $index,
      from => $self->from,
      size => $self->size,
      body => {
         query => $query,
      },
   );

   return $r;
}

sub get_from_id {
   my $self = shift;
   my ($id, $index, $type) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('get_from_id', $id) or return;
   $self->brik_help_run_undef_arg('get_from_id', $index) or return;
   $self->brik_help_run_undef_arg('get_from_id', $type) or return;

   my $r = $elk->get(
      index => $index,
      type => $type,
      id => $id,
   );

   return $r;
}

sub www_search {
   my $self = shift;
   my ($query, $index) = @_;

   $index ||= $self->index;
   $self->brik_help_run_undef_arg('www_search', $index) or return;
   $self->brik_help_run_undef_arg('www_search', $query) or return;

   my $size = $self->size;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $nodes = $self->nodes;
   for my $node (@$nodes) {
      # http://localhost:9200/INDEX/_search/?size=SIZE&q=QUERY
      my $url = "$node/$index/_search/?size=$size&q=".$query;

      my $get = $self->SUPER::get($url) or next;
      my $body = $get->{content};

      my $decoded = $sj->decode($body) or next;

      return $decoded;
   }

   return;
}

sub delete_index {
   my $self = shift;
   my ($index) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('delete_index', $index) or return;

   my $r = $elk->indices->delete(
      index => $index,
   );

   return $r;
}

sub show_indices {
   my $self = shift;
 
   my $nodes = $self->nodes;
   $self->brik_help_run_undef_arg('show_indices', $nodes) or return;
   $self->brik_help_run_invalid_arg('show_indices', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('show_indices', $nodes) or return;

   my $uri = $nodes->[0];

   $self->log->verbose("show_indices: uri[$uri]");

   my $get = $self->SUPER::get("$uri/_cat/indices?pretty=true") or return;
   if ($self->code ne 200) {
      return $self->log->error("show_indices: failed with content [".$get->{content}."]");
   }
   my $content = $get->{content};
   if (! defined($content)) {
      return;
   }

   my @lines = split(/\n/, $content);

   if (@lines == 0) {
      return $self->log->warning("show_indices: nothing returned, no index?");
      return 1;
   }

   return \@lines;
}

sub get_index {
   my $self = shift;
   my ($index) = @_;
 
   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('get_index', $index) or return;

   my $r = $elk->indices->get(
      index => $index,
   );

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-mapping.html
#
# GET http://192.168.0.IP:9200/INDEX/_mapping/DOCUMENT
#
sub get_mappings {
   my $self = shift;
   my ($index) = @_;

   $index ||= $self->index;
   $self->brik_help_run_undef_arg('get_mappings', $index) or return;

   my $r = $self->get_index($index) or return;
   if (exists($r->{$index}) && exists($r->{$index}{mappings})) {
      return $r->{$index}{mappings};
   }

   return $self->log->error("get_mappings: index or mappings not found");
}

sub create_index {
   my $self = shift;
   my ($index) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('create_index', $index) or return;
         
   my $r = $elk->indices->create(
      index => $index,
   );
   
   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-put-mapping.html
#
sub create_index_with_mappings {
   my $self = shift;
   my ($index, $mappings) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('create_index_with_mappings', $index) or return;
   $self->brik_help_run_undef_arg('create_index_with_mappings', $mappings) or return;
   $self->brik_help_run_invalid_arg('create_index_with_mappings', $mappings, 'HASH') or return;

   my $r = $elk->indices->create(
      index => $index,
      body => {
         mappings => $mappings,
      },
   );

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch - client::elasticsearch Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
