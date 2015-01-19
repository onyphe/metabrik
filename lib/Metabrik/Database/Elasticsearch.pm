#
# $Id$
#
# database::elasticsearch Brik
#
package Metabrik::Database::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable elasticsearch elk) ],
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
         nodes => [ qw(localhost:9200) ],
         cxn_pool => 'Sniff',
         bulk_mode => 0,
         from => 0,
         size => 10,
      },
      commands => {
         open => [ ],
         index => [ qw(document index|OPTIONAL type|OPTIONAL) ],
         index_bulk => [ qw(document) ],
         search => [ qw($query_hash index|OPTIONAL) ],
         count => [ qw(index|OPTIONAL type|OPTIONAL) ],
         get => [ qw(id index|OPTIONAL type|OPTIONAL) ],
         www_search => [ qw(query index|OPTIONAL) ],
      },
      require_modules => {
         'Search::Elasticsearch' => [ ],
         'Metabrik::Client::Www' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($index, $type) = @_;

   my $nodes = $self->nodes;
   my $cxn_pool = $self->cxn_pool;

   my $elk = Search::Elasticsearch->new(
      nodes => $nodes,
      cxn_pool => $cxn_pool,
   );
   if (! defined($elk)) {
      return $self->log->error("open: connection failed");
   }

   if ($self->bulk_mode) {
      $index ||= $self->index_name;
      if (! defined($index)) {
         return $self->log->error($self->brik_help_set('index_name'));
      }

      $type ||= $self->type_document;
      if (! defined($type)) {
         return $self->log->error($self->brik_help_set('type_document'));
      }

      my $bulk = $elk->bulk_helper(
         index => $index,
         type => $type,
      );
      if (! defined($bulk)) {
         return $self->log->error("open: bulk connection failed");
      }

      return $self->_bulk($bulk);
   }

   return $self->_elk($elk);
}

sub index {
   my $self = shift;
   my ($doc, $index, $type) = @_;

   my $elk = $self->_elk;
   if (! defined($elk)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if (! defined($doc)) {
      return $self->log->error($self->brik_help_run('index'));
   }

   if (ref($doc) ne 'HASH') {
      return $self->log->error("index: argument 1 MUST be HASHREF");
   }

   $index ||= $self->index_name;
   if (! defined($index)) {
      return $self->log->error($self->brik_help_set('index_name'));
   }

   $type ||= $self->type_document;
   if (! defined($type)) {
      return $self->log->error($self->brik_help_set('type_document'));
   }

   my $r = $elk->index(
      index => $index,
      type => $type,
      body => $doc,
   );

   $self->log->verbose("index: indexation done");

   return $r;
}

sub index_bulk {
   my $self = shift;
   my ($doc) = @_;

   # No check for speed improvements
   return $self->_bulk->index({ source => $doc });
}

sub count {
   my $self = shift;
   my ($index, $type) = @_;

   my $elk = $self->_elk;
   if (! defined($elk)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   $index ||= $self->index_name;
   if (! defined($index)) {
      return $self->log->error($self->brik_help_set('index_name'));
   }

   $type ||= $self->type_document;
   if (! defined($type)) {
      return $self->log->error($self->brik_help_set('type_document'));
   }

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

# http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-multi-match-query.html

sub search {
   my $self = shift;
   my ($query, $index) = @_;

   my $elk = $self->_elk;
   if (! defined($elk)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if (! defined($query)) {
      return $self->log->error($self->brik_help_run('search'));
   }

   if (ref($query) ne 'HASH') {
      return $self->log->error("index: argument 1 MUST be HASHREF");
   }

   $index ||= $self->index_name;
   if (! defined($index)) {
      return $self->log->error($self->brik_help_set('index_name'));
   }

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
   if (! defined($elk)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if (! defined($id)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   $index ||= $self->index_name;
   if (! defined($index)) {
      return $self->log->error($self->brik_help_set('index_name'));
   }

   $type ||= $self->type_document;
   if (! defined($type)) {
      return $self->log->error($self->brik_help_set('type_document'));
   }

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

   if (! defined($query)) {
      return $self->log->error($self->brik_help_run('www_search'));
   }

   $index_name ||= $self->index_name;
   if (! defined($index_name)) {
      return $self->log->error($self->brik_help_set('index_name'));
   }

   my $size = $self->size;

   my $client_www = Metabrik::Client::Www->new_from_brik($self) or return;

   my $nodes = $self->nodes;
   for my $node (@$nodes) {
      # http://localhost:9200/INDEX/_search/?size=SIZE&q=QUERY
      my $url = "$node/$index_name/_search/?size=$size&q=".$query;

      my $get = $client_www->get($url);
      if (! defined($get)) {
         $self->log->warning("www_search: get failed");
         next;
      }

      my $body = $get->{body};
      my $string_json = Metabrik::String::Json->new_from_brik($self) or return;
      my $decoded = $string_json->decode($body)
         or return $self->log->error("www_search: decode failed");

      return $decoded;
   }

   return;
}

1;

__END__

=head1 NAME

Metabrik::Database::Elasticsearch - database::elasticsearch Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
