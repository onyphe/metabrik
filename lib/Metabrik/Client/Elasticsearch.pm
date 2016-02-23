#
# $Id$
#
# client::elasticsearch Brik
#
package Metabrik::Client::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::System::Service Metabrik::System::Package Metabrik::Client::Rest);

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
         index_name => [ qw(index_name) ],
         type_document => [ qw(type_document) ],
         bulk_mode => [ qw(0|1) ],
         from => [ qw(number) ],
         size => [ qw(count) ],
         _elk => [ qw(INTERNAL) ],
         _bulk => [ qw(INTERNAL) ],
      },
      attributes_default => {
         nodes => [ qw(http://localhost:9200) ],
         cxn_pool => 'Sniff',
         bulk_mode => 0,
         from => 0,
         size => 10,
      },
      commands => {
         install => [ ], # Inherited
         open => [ qw(index|OPTIONAL type|OPTIONAL) ],
         index => [ qw(document index|OPTIONAL type|OPTIONAL) ],
         index_bulk => [ qw(document) ],
         query => [ qw($query_hash index|OPTIONAL) ],
         count => [ qw(index|OPTIONAL type|OPTIONAL) ],
         get => [ qw(id index|OPTIONAL type|OPTIONAL) ],
         www_search => [ qw(query index|OPTIONAL) ],
         delete => [ qw(index) ],
         start => [ ], # Inherited
         stop => [ ], # Inherited
         status => [ ], # Inherited
         list_indices => [ ],
         get_index => [ qw(index) ],
         get_mappings => [ qw(index) ],
         create_index => [ qw(index) ],
         create_index_with_mappings => [ qw(index mappings) ],
         # XXX: ./bin/plugin -install lmenezes/elasticsearch-kopf
         #install_plugin => [ qw(plugin) ],
      },
      require_modules => {
         'Search::Elasticsearch' => [ ],
         'Metabrik::Client::Rest' => [ ],
         'Metabrik::Client::Www' => [ ],
         'Metabrik::String::Json' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(elasticsearch) ],
      },
      need_services => {
         ubuntu => [ qw(elasticsearch) ],
      },
   };
}

sub open {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index_name;
   $type ||= $self->type_document;
   $self->brik_help_run_undef_arg('open', $index) or return;
   $self->brik_help_run_undef_arg('open', $type) or return;

   my $nodes = $self->nodes;
   my $cxn_pool = $self->cxn_pool;

   my $elk = Search::Elasticsearch->new(
      nodes => $nodes,
      cxn_pool => $cxn_pool,
   );
   if (! defined($elk)) {
      return $self->log->error("open: connection failed");
   }

   $self->_elk($elk);

   if ($self->bulk_mode) {
      my $bulk = $elk->bulk_helper(
         index => $index,
         type => $type,
      );
      if (! defined($bulk)) {
         return $self->log->error("open: bulk connection failed");
      }

      return $self->_bulk($bulk);
   }

   return $nodes;
}

sub index {
   my $self = shift;
   my ($doc, $index, $type) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index_name;
   $type ||= $self->type_document;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('index', $index) or return;
   $self->brik_help_run_undef_arg('index', $type) or return;
   $self->brik_help_run_undef_arg('index', $doc) or return;
   $self->brik_help_run_invalid_arg('index', $doc, 'HASH') or return;

   my $r = $elk->index(
      index => $index,
      type => $type,
      body => $doc,
   );

   return $r;
}

sub index_bulk {
   my $self = shift;
   my ($doc) = @_;

   my $bulk = $self->_bulk;
   $self->brik_help_run_undef_arg('open', $bulk) or return;
   $self->brik_help_run_undef_arg('index_bulk', $doc) or return;

   return $self->_bulk->index({ source => $doc });
}

sub count {
   my $self = shift;
   my ($index, $type) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index_name;
   $type ||= $self->type_document;
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
   $index ||= $self->index_name;
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

sub get {
   my $self = shift;
   my ($id, $index, $type) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index_name;
   $type ||= $self->type_document;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('get', $id) or return;
   $self->brik_help_run_undef_arg('get', $index) or return;
   $self->brik_help_run_undef_arg('get', $type) or return;

   my $r = $elk->get(
      index => $index,
      type => $type,
      id => $id,
   );

   return $r;
}

sub www_search {
   my $self = shift;
   my ($query, $index_name) = @_;

   $index_name ||= $self->index_name;
   $self->brik_help_run_undef_arg('www_search', $index_name) or return;
   $self->brik_help_run_undef_arg('www_search', $query) or return;

   my $size = $self->size;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $nodes = $self->nodes;
   for my $node (@$nodes) {
      # http://localhost:9200/INDEX/_search/?size=SIZE&q=QUERY
      my $url = "$node/$index_name/_search/?size=$size&q=".$query;

      my $get = $cw->get($url) or next;
      my $body = $get->{content};

      my $decoded = $sj->decode($body) or next;

      return $decoded;
   }

   return;
}

sub delete {
   my $self = shift;
   my ($index) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index_name;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('delete', $index) or return;

   my $r = $elk->indices->delete(
      index => $index,
   );

   return $r;
}

sub list_indices {
   my $self = shift;
 
   my $nodes = $self->nodes;
   $self->brik_help_run_undef_arg('list_indices', $nodes) or return;
   $self->brik_help_run_invalid_arg('list_indices', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('list_indices', $nodes) or return;

   my $uri = $nodes->[0];

   $self->log->verbose("list_indices: uri[$uri]");

   my $get = $self->SUPER::get("$uri/_cat/indices?pretty=true") or return;
   if ($self->code ne 200) {
      return $self->log->error("list_indices: failed with content [".$get->{content}."]");
   }
   my $content = $get->{content} or return;

   my @lines = split(/\n/, $content);

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

   $index ||= $self->index_name;
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
