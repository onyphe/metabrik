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
         type_entry => [ qw(type_entry) ],
         _elk => [ qw(INTERNAL) ],
      },
      attributes_default => {
         nodes => [ qw(localhost:9200) ],
         cxn_pool => 'Sniff',
      },
      commands => {
         open => [ ],
         index => [ qw(document index|OPTIONAL type|OPTIONAL) ],
         search => [ qw($query_hash index|OPTIONAL) ],
         count => [ qw(index|OPTIONAL type|OPTIONAL) ],
         get => [ qw(id index|OPTIONAL type|OPTIONAL) ],
      },
      require_modules => {
         'Search::Elasticsearch' => [ ],
      },
   };
}

sub open {
   my $self = shift;

   my $nodes = $self->nodes;
   my $cxn_pool = $self->cxn_pool;

   my $elk = Search::Elasticsearch->new(
      nodes => $nodes,
      cxn_pool => $cxn_pool,
   );
   if (! defined($elk)) {
      return $self->log->error("open: connection failed");
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

   $type ||= $self->type_entry;
   if (! defined($type)) {
      return $self->log->error($self->brik_help_set('type_entry'));
   }

   my $r = $elk->index(
      index => $index,
      type => $type,
      body => $doc,
   );

   $self->log->verbose("index: indexation done");

   return $r;
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

   $type ||= $self->type_entry;
   if (! defined($type)) {
      return $self->log->error($self->brik_help_set('type_entry'));
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
      # from => 0,
      # size => $number_of_items, then you increment the from to the number of returned result and stop when the number of result is less than size you wanted. Or you can use Scrolled Search
      body => {
         query => {
            match => $query,
         },
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

   $type ||= $self->type_entry;
   if (! defined($type)) {
      return $self->log->error($self->brik_help_set('type_entry'));
   }

   my $r = $elk->get(
      index => $index,
      type => $type,
      id => $id,
   );

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Database::Elasticsearch - database::elasticsearch Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
