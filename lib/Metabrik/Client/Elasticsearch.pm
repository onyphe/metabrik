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
         max => [ qw(count) ],
         _elk => [ qw(INTERNAL) ],
         _bulk => [ qw(INTERNAL) ],
         _scroll => [ qw(INTERNAL) ],
      },
      attributes_default => {
         nodes => [ qw(http://localhost:9200) ],
         cxn_pool => 'Sniff',
         from => 0,
         size => 10,
         max => 0,
      },
      commands => {
         open => [ qw(nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         open_bulk_mode => [ qw(index|OPTIONAL type|OPTIONAL nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         open_scroll_scan_mode => [ qw(index|OPTIONAL size|OPTIONAL nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         total_scroll => [ ],
         next_scroll => [ ],
         index_document => [ qw(document index|OPTIONAL type|OPTIONAL) ],
         index_bulk => [ qw(document index|OPTIONAL type|OPTIONAL) ],
         bulk_flush => [ ],
         query => [ qw($query_hash index|OPTIONAL) ],
         count => [ qw(index|OPTIONAL type|OPTIONAL) ],
         get_from_id => [ qw(id index|OPTIONAL type|OPTIONAL) ],
         www_search => [ qw(query index|OPTIONAL) ],
         delete_index => [ qw(index_or_indices_list) ],
         show_indices => [ qw(nodes_list|OPTIONAL) ],
         list_indices => [ qw(nodes_list|OPTIONAL) ],
         get_index => [ qw(index) ],
         get_aliases => [ qw(index) ],
         get_mappings => [ qw(index) ],
         create_index => [ qw(index) ],
         create_index_with_mappings => [ qw(index mappings) ],
         get_templates => [ qw(nodes_list|OPTIONAL) ],
         list_templates => [ qw(nodes_list|OPTIONAL) ],
         get_template => [ qw(name) ],
         put_template => [ qw(name template) ],
         put_template_from_json_file => [ qw(file) ],
         get_settings => [ qw(index_or_indices_list|OPTIONAL name_or_names_list|OPTIONAL) ],
         put_settings => [ qw(settings_hash index_or_indices_list|OPTIONAL) ],
         delete_template => [ qw(name) ],
         is_index_exists => [ qw(index) ],
         is_type_exists => [ qw(index type) ],
         is_document_exists => [ qw(index type document) ],
         refresh_index => [ qw(index) ],
         export_as_csv => [ qw(index output_csv size) ],
         import_from_csv => [ qw(input_csv index|OPTIONAL type|OPTIONAL) ],
         get_stats_process => [ qw(nodes_list|OPTIONAL) ],
         get_process => [ qw(nodes_list|OPTIONAL) ],
         get_cluster_state => [ qw(nodes_list|OPTIONAL) ],
         get_cluster_health => [ qw(nodes_list|OPTIONAL) ],
         count_green_shards => [ ],
         count_yellow_shards => [ ],
         count_red_shards => [ ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::File::Csv' => [ ],
         'Metabrik::File::Json' => [ ],
         'Search::Elasticsearch' => [ ],
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

   for my $node (@$nodes) {
      if ($node !~ m{https?://}) {
         return $self->log->error("open: invalid node[$node], must start with http(s)");
      }
   }

   my $nodes_str = join('|', @$nodes);
   $self->log->verbose("open: using nodes [$nodes_str]");

   my $elk = Search::Elasticsearch->new(
      nodes => $nodes,
      cxn_pool => $cxn_pool,
      timeout => 60,
      max_retries => 3,
      retry_on_timeout => 1,
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

sub open_scroll_scan_mode {
   my $self = shift;
   my ($index, $size, $nodes, $cxn_pool) = @_;

   $index ||= $self->index;
   $size ||= $self->size;
   $nodes ||= $self->nodes;
   $cxn_pool ||= $self->cxn_pool;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $index) or return;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $size) or return;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $nodes) or return;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $cxn_pool) or return;
   $self->brik_help_run_invalid_arg('open_scroll_scan_mode', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('open_scroll_scan_mode', $nodes) or return;

   $self->open($nodes, $cxn_pool) or return;

   my $elk = $self->_elk;

   my $scroll = $elk->scroll_helper(
      index => $index,
      search_type => 'scan',
      size => $size,
   );
   if (! defined($scroll)) {
      return $self->log->error("open_scroll_scan_mode: failed");
   }

   $self->_scroll($scroll);

   return $nodes;
}

sub total_scroll {
   my $self = shift;

   my $scroll = $self->_scroll;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $scroll) or return;

   return $scroll->total;
}

sub next_scroll {
   my $self = shift;

   my $scroll = $self->_scroll;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $scroll) or return;

   return $scroll->next;
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

   my $r;
   eval {
      $r = $elk->index(
         index => $index,
         type => $type,
         body => $doc,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("index_document: index failed for index [$index]: [$@]");
   }

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

   return $bulk->index({ source => $doc });
}

sub bulk_flush {
   my $self = shift;

   my $bulk = $self->_bulk;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;

   return $bulk->flush;
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

   my $r;
   eval {
      $r = $elk->search(
         index => $index,
         type => $type,
         search_type => 'count',
         body => {
            query => {
               match_all => {},
            },
         },
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("count: search failed for index [$index]: [$@]");
   }

   return $r->{hits}{total};
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/full-text-queries.html
# https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html
#
# Example: my $q = { query => { term => { ip => "192.168.57.19" } } }
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

   my $r;
   eval {
      $r = $elk->search(
         index => $index,
         from => $self->from,
         size => $self->size,
         body => $query,
         #timeout => 60,  # XXX: to test
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("query: failed for index [$index]: [$@]");
   }

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

   my $r;
   eval {
      $r = $elk->get(
         index => $index,
         type => $type,
         id => $id,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_from_id: get failed for index [$index]: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/search-uri-request.html
#
sub www_search {
   my $self = shift;
   my ($query, $index) = @_;

   $index ||= $self->index;
   $self->brik_help_run_undef_arg('www_search', $index) or return;
   $self->brik_help_run_undef_arg('www_search', $query) or return;

   my $from = $self->from;
   my $size = $self->size;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $nodes = $self->nodes;
   for my $node (@$nodes) {
      # http://localhost:9200/INDEX/_search/?size=SIZE&q=QUERY
      my $url = "$node/$index/_search/?from=$from&size=$size&q=".$query;

      my $get = $self->SUPER::get($url) or next;
      my $body = $get->{content};

      my $decoded = $sj->decode($body) or next;

      return $decoded;
   }

   return;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub delete_index {
   my $self = shift;
   my ($index) = @_;

   my $elk = $self->_elk;
   $index ||= $self->index;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('delete_index', $index) or return;
   $self->brik_help_run_invalid_arg('delete_index', $index, 'ARRAY', 'SCALAR') or return;

   my $r;
   eval {
      $r = $elk->indices->delete(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_index: delete failed for index [$index]: [$@]");
   }

   return $r;
}

sub show_indices {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('show_indices', $nodes) or return;
   $self->brik_help_run_invalid_arg('show_indices', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('show_indices', $nodes) or return;

   my $uri = $nodes->[0];

   $self->log->verbose("show_indices: uri[$uri]");

   my $get = $self->SUPER::get("$uri/_cat/indices") or return;
   if ($self->code ne 200) {
      return $self->log->error("show_indices: failed with content [".$get->{content}."]");
   }
   my $content = $get->{content};
   if (! defined($content)) {
      return;
   }

   my @lines = split(/\n/, $content);

   if (@lines == 0) {
      $self->log->warning("show_indices: nothing returned, no index?");
   }

   return \@lines;
}

sub list_indices {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('list_indices', $nodes) or return;
   $self->brik_help_run_invalid_arg('list_indices', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('list_indices', $nodes) or return;

   my $lines = $self->show_indices or return;
   if (@$lines == 0) {
      $self->log->warning("list_indices: no index found");
      return [];
   }

   # Format depends on ElasticSearch version. We try to detect the format.
   my @indices = ();
   for (@$lines) {
      my @t = split(/\s+/);
      if (@t == 9) {
         push @indices, $t[2];
      }
      elsif (@t == 8) {
         push @indices, $t[1];
      }
   }

   return [ sort { $a cmp $b } @indices ];
}

sub get_index {
   my $self = shift;
   my ($index) = @_;
 
   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('get_index', $index) or return;

   my $r;
   eval {
      $r = $elk->indices->get(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_index: get failed for index [$index]: [$@]");
   }

   return $r;
}

sub get_aliases {
   my $self = shift;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;

   my $r;
   eval {
      $r = $elk->indices->get_aliases;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_aliases: get_aliases failed: [$@]");
   }

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
         
   my $r;
   eval {
      $r = $elk->indices->create(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_index: create failed for index [$index]: [$@]");
   }
   
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

   my $r;
   eval {
      $r = $elk->indices->create(
         index => $index,
         body => {
            mappings => $mappings,
         },
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_index_with_mappings: create failed for index [$index]: [$@]");
   }

   return $r;
}

# GET http://localhost:9200/_template/
sub get_templates {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('get_templates', $nodes) or return;
   $self->brik_help_run_invalid_arg('get_templates', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('get_templates', $nodes) or return;

   my $first = $nodes->[0];

   $self->get($first.'/_template') or return;
   my $content = $self->content or return;

   return $content;
}

sub list_templates {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('list_templates', $nodes) or return;
   $self->brik_help_run_invalid_arg('list_templates', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('list_templates', $nodes) or return;

   my $content = $self->get_templates($nodes) or return;

   return [ sort { $a cmp $b } keys %$content ];
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub get_template {
   my $self = shift;
   my ($template) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('get_template', $template) or return;

   my $r;
   eval {
      $r = $elk->indices->get_template(
         name => $template,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_template: template failed for name [$template]: [$@]");
   }

   return $r;
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub put_template {
   my $self = shift;
   my ($name, $template) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('put_template', $name) or return;
   $self->brik_help_run_undef_arg('put_template', $template) or return;
   $self->brik_help_run_invalid_arg('put_template', $template, 'HASH') or return;

   my $r;
   eval {
      $r = $elk->indices->put_template(
         name => $name,
         body => $template,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_template: template failed for name [$name]: [$@]");
   }

   return $r;
}

sub put_template_from_json_file {
   my $self = shift;
   my ($json_file) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('put_template_from_json_file', $json_file) or return;
   $self->brik_help_run_file_not_found('put_template_from_json_file', $json_file) or return;

   my $fj = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $data = $fj->read($json_file) or return;

   if (! exists($data->{template})) {
      return $self->log->error("put_template_from_json_file: no template name found");
   }

   my $name = $data->{template};

   return $self->put_template($name, $data);
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-settings.html
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub get_settings {
   my $self = shift;
   my ($indices, $names) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;

   my %args = ();
   if (defined($indices)) {
      $self->brik_help_run_undef_arg('get_settings', $indices) or return;
      my $ref = $self->brik_help_run_invalid_arg('get_settings', $indices, 'ARRAY', 'SCALAR')
         or return;
      $args{index} = $indices;
   }
   if (defined($names)) {
      $self->brik_help_run_file_not_found('get_settings', $names) or return;
      my $ref = $self->brik_help_run_invalid_arg('get_settings', $names, 'ARRAY', 'SCALAR')
         or return;
      $args{name} = $names;
   }

   my $r;
   eval {
      $r = $elk->indices->get_settings(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_settings: failed: [$@]");
   }

   return $r;
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-settings.html
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
# Example:
#
# run client::elasticsearch put_settings "{ index => { refresh_interval => -1 } }"
#
sub put_settings {
   my $self = shift;
   my ($settings, $indices) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('put_settings', $settings) or return;
   $self->brik_help_run_invalid_arg('put_settings', $settings, 'HASH') or return;

   my %args = (
      body => $settings,
   );
   if (defined($indices)) {
      $self->brik_help_run_undef_arg('put_settings', $indices) or return;
      my $ref = $self->brik_help_run_invalid_arg('put_settings', $indices, 'ARRAY', 'SCALAR')
         or return;
      $args{index} = $indices;
   }

   my $r;
   eval {
      $r = $elk->indices->put_settings(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_settings: failed: [$@]");
   }

   return $r;
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub delete_template {
   my $self = shift;
   my ($name) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('delete_template', $name) or return;

   my $r;
   eval {
      $r = $elk->indices->delete_template(
         name => $name,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_template: failed for name [$name]: [$@]");
   }

   return $r;
}

#
# Return a boolean to state for index existence
#
sub is_index_exists {
   my $self = shift;
   my ($index) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('is_index_exists', $index) or return;

   my $r;
   eval {
      $r = $elk->indices->exists(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_index_exists: failed for index [$index]: [$@]");
   }

   return $r ? 1 : 0;
}

#
# Return a boolean to state for index with type existence
#
sub is_type_exists {
   my $self = shift;
   my ($index, $type) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('is_type_exists', $index) or return;
   $self->brik_help_run_undef_arg('is_type_exists', $type) or return;

   my $r;
   eval {
      $r = $elk->indices->exists_type(
         index => $index,
         type => $type,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_type_exists: failed for index [$index] and ".
         "type [$type]: [$@]");
   }

   return $r ? 1 : 0;
}

#
# Return a boolean to state for document existence
#
sub is_document_exists {
   my $self = shift;
   my ($index, $type, $document) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $index) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $type) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $document) or return;
   $self->brik_help_run_invalid_arg('is_document_exists', $document, 'HASH') or return;

   my $r;
   eval {
      $r = $elk->exists(
         index => $index,
         type => $type,
         %$document,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_document_exists: failed for index [$index] and ".
         "type [$type]: [$@]");
   }

   return $r ? 1 : 0;
}

#
# Refresh an index to receive latest additions
#
sub refresh_index {
   my $self = shift;
   my ($index) = @_;

   my $elk = $self->_elk;
   $self->brik_help_run_undef_arg('open', $elk) or return;
   $self->brik_help_run_undef_arg('refresh_index', $index) or return;

   my $r;
   eval {
      $r = $elk->indices->refresh(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("refresh_index: failed for index [$index]: [$@]");
   }

   return $r;
}

sub export_as_csv {
   my $self = shift;
   my ($index, $output_csv, $size) = @_;

   $self->brik_help_run_undef_arg('export_as_csv', $index) or return;
   $self->brik_help_run_undef_arg('export_as_csv', $output_csv) or return;
   $self->brik_help_run_undef_arg('export_as_csv', $size) or return;

   my $max = $self->max;

   my $scroll = $self->open_scroll_scan_mode($index, $size) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->separator(',');
   $fc->append(1);
   $fc->first_line_is_header(0);
   $fc->write_header(1);
   $fc->use_quoting(1);

   my $total = $self->total_scroll;
   $self->log->info("export_as_csv: total [$total]");

   my $first = $self->next_scroll;
   if (! defined($first) || ! exists($first->{_source})) {
      return $self->log->error("export_as_csv: nothing in index [$index]?");
   }

   my $doc = $first->{_source};

   my @header = ();
   for my $this (keys %$doc) {
      if (ref($doc->{$this}) eq 'HASH') {
         for my $k (sort { $a cmp $b } keys %{$doc->{$this}}) {
            push @header, "$this.$k";  # Object field notation.
         }
      }
      # For an ARRAY, we have nothing special todo.
      else {
         push @header, $this;
      }
   }
   $fc->header(\@header);

   # Handle this first entry now.
   my $h = {};
   for my $this (keys %$doc) {
      my $ref = ref($doc->{$this});
      if ($ref eq 'HASH') {   # An object lies here.
         for my $k (keys %{$doc->{$this}}) {
            $h->{"$this.$k"} = $doc->{$this}{$k};
         }
      }
      elsif ($ref eq 'ARRAY') {  # An ARRAY lies here.
         $h->{$this} = join('|', @{$doc->{$this}});
      }
      else {
         $h->{$this} = $doc->{$this};
      }
   }
   $fc->write([ $h ], $output_csv) or return;

   # And all other entries.
   my $processed = 0;
   while (my $this = $self->next_scroll) {
      my $doc = $this->{_source};

      my $h = {};
      for my $this (keys %$doc) {
         my $ref = ref($doc->{$this});
         if ($ref eq 'HASH') {   # An object lies here.
            for my $k (keys %{$doc->{$this}}) {
               $h->{"$this.$k"} = $doc->{$this}{$k};
            }
         }
         elsif ($ref eq 'ARRAY') {  # An ARRAY lies here.
            $h->{$this} = join('|', @{$doc->{$this}});
         }
         else {
            $h->{$this} = $doc->{$this};
         }
      }

      $fc->write([ $h ], $output_csv) or return;

      # Log a status sometimes.
      if (! (++$processed % 100_000)) {
         $self->log->verbose("export_as_csv: fetched [$processed/$total] elements");
      }

      # Limit export to specified maximum
      if ($max > 0 && $processed >= $max) {
         $self->log->verbose("export_from_csv: max export reached [$processed]");
         last;
      }
   }

   return $output_csv;
}

sub import_from_csv {
   my $self = shift;
   my ($input_csv, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('import_from_csv', $input_csv) or return;
   $self->brik_help_run_file_not_found('import_from_csv', $input_csv) or return;
   $self->brik_help_run_undef_arg('import_from_csv', $index) or return;
   $self->brik_help_run_undef_arg('import_from_csv', $type) or return;

   my $max = $self->max;

   $self->open_bulk_mode($index, $type) or return;

   $self->log->verbose("import_from_csv: importing to index [$index] with type [$type]");

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->separator(',');
   $fc->first_line_is_header(1);

   my $processed = 0;
   while (my $this = $fc->read_next($input_csv)) {
      my $h = {};
      for my $key (keys %$this) {
         if ($key =~ m{^(\S+)\.(\S+)$}) {  # An OBJECT is waiting
            my $k = $1;
            my $v = $2;
            $h->{$k}{$v} = $this->{$key};
         }
         else {
            if ($this->{$key} =~ m{\|}) { # An ARRAY is waiting
               $h->{$key} = [ split('\|', $this->{$key}) ];
            }
            else {
               $h->{$key} = $this->{$key};
            }
         }
      }

      $self->index_bulk($h, $index, $type) or return;

      # Log a status sometimes.
      if (! (++$processed % 100_000)) {
         $self->log->verbose("import_from_csv: processed [$processed] entries");
      }

      # Limit import to specified maximum
      if ($max > 0 && $processed >= $max) {
         $self->log->verbose("import_from_csv: max import reached [$processed]");
         last;
      }
   }

   $self->bulk_flush or return;

   $self->refresh_index($index) or return;

   return $processed;
}

# http://localhost:9200/_nodes/stats/process?pretty
sub get_stats_process {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('get_stats_process', $nodes) or return;
   $self->brik_help_run_invalid_arg('get_stats_process', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('get_stats_process', $nodes) or return;

   my @content_list = ();
   for my $node (@$nodes) {
      my $r = $self->get($node.'/_nodes/stats/process');
      if (! defined($r)) {
         $self->log->warning("get_stats_process: unable to retrieve stats for node [$node]");
         next;
      }
      my $content = $self->content;
      if (! defined($content)) {
         $self->log->warning("get_stats_process: unable to retrieve content for node [$node]");
         next;
      }
      push @content_list, $content;
   }

   return \@content_list;
}

# curl http://localhost:9200/_nodes/process?pretty
sub get_process {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('get_process', $nodes) or return;
   $self->brik_help_run_invalid_arg('get_process', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('get_process', $nodes) or return;

   my @content_list = ();
   for my $node (@$nodes) {
      my $r = $self->get($node.'/_nodes/process');
      if (! defined($r)) {
         $self->log->warning("get_process: unable to retrieve process for node [$node]");
         next;
      }
      my $content = $self->content;
      if (! defined($content)) {
         $self->log->warning("get_process: unable to retrieve content for node [$node]");
         next;
      }
      push @content_list, $content;
   }

   return \@content_list;
}

# curl -XGET 'http://localhost:9200/_cluster/state?pretty'
sub get_cluster_state {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('get_cluster_state', $nodes) or return;
   $self->brik_help_run_invalid_arg('get_cluster_state', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('get_cluster_state', $nodes) or return;

   my @content_list = ();
   for my $node (@$nodes) {
      my $r = $self->get($node.'/_cluster/state');
      if (! defined($r)) {
         $self->log->warning("get_cluster_state: unable to retrieve state for node [$node]");
         next;
      }
      my $content = $self->content;
      if (! defined($content)) {
         $self->log->warning("get_cluster_state: unable to retrieve content for node [$node]");
         next;
      }
      push @content_list, $content;
   }

   return \@content_list;
}

# curl -XGET 'http://localhost:9200/_cluster/health?pretty'
sub get_cluster_health {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('get_cluster_health', $nodes) or return;
   $self->brik_help_run_invalid_arg('get_cluster_health', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('get_cluster_health', $nodes) or return;

   my @content_list = ();
   for my $node (@$nodes) {
      my $r = $self->get($node.'/_cluster/health');
      if (! defined($r)) {
         $self->log->warning("get_cluster_health: unable to retrieve health for node [$node]");
         next;
      }
      my $content = $self->content;
      if (! defined($content)) {
         $self->log->warning("get_cluster_health: unable to retrieve content for node [$node]");
         next;
      }
      push @content_list, $content;
   }

   return \@content_list;

}

sub count_green_shards {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count = 0;
   for (@$get) {
      if (/^\s*green\s+/) {
         $count++;
      }
   }

   return $count;
}

sub count_yellow_shards {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count = 0;
   for (@$get) {
      if (/^\s*yellow\s+/) {
         $count++;
      }
   }

   return $count;
}

sub count_red_shards {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count = 0;
   for (@$get) {
      if (/^\s*red\s+/) {
         $count++;
      }
   }

   return $count;
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch - client::elasticsearch Brik

=head1 SYNOPSIS

   host:~> my $q = { term => { ip => "192.168.57.19" } }
   host:~> run client::elasticsearch open
   host:~> run client::elasticsearch query $q data-*

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
