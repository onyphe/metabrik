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
      tags => [ qw(unstable es es) ],
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
         rtimeout => [ qw(seconds) ],
         sniff_rtimeout => [ qw(seconds) ],
         try => [ qw(count) ],
         _es => [ qw(INTERNAL) ],
         _bulk => [ qw(INTERNAL) ],
         _scroll => [ qw(INTERNAL) ],
      },
      attributes_default => {
         nodes => [ qw(http://localhost:9200) ],
         cxn_pool => 'Sniff',
         from => 0,
         size => 10,
         max => 0,
         index => '*',
         type => '*',
         rtimeout => 60,
         sniff_rtimeout => 3,
         try => 3,
      },
      commands => {
         open => [ qw(nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         open_bulk_mode => [ qw(index|OPTIONAL type|OPTIONAL nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         open_scroll_scan_mode => [ qw(index|OPTIONAL size|OPTIONAL nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         open_scroll => [ qw(index|OPTIONAL size|OPTIONAL nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         close_scroll => [ ],
         total_scroll => [ ],
         next_scroll => [ ],
         index_document => [ qw(document index|OPTIONAL type|OPTIONAL id|OPTIONAL) ],
         index_bulk => [ qw(document index|OPTIONAL type|OPTIONAL id|OPTIONAL) ],
         bulk_flush => [ ],
         query => [ qw($query_hash index|OPTIONAL type|OPTIONAL) ],
         count => [ qw(index|OPTIONAL type|OPTIONAL) ],
         get_from_id => [ qw(id index|OPTIONAL type|OPTIONAL) ],
         www_search => [ qw(query index|OPTIONAL type|OPTIONAL) ],
         delete_index => [ qw(index|indices_list) ],
         show_indices => [ ],
         show_nodes => [ ],
         show_health => [ ],
         show_recovery => [ ],
         list_indices => [ ],
         get_indices => [ ],
         get_index => [ qw(index|indices_list) ],
         list_indices_version => [ qw(index|indices_list) ],
         open_index => [ qw(index|indices_list) ],
         close_index => [ qw(index|indices_list) ],
         get_aliases => [ qw(index) ],
         get_mappings => [ qw(index) ],
         create_index => [ qw(index) ],
         create_index_with_mappings => [ qw(index mappings) ],
         info => [ qw(nodes_list|OPTIONAL) ],
         version => [ qw(nodes_list|OPTIONAL) ],
         get_templates => [ ],
         list_templates => [ ],
         get_template => [ qw(name) ],
         put_template => [ qw(name template) ],
         put_template_from_json_file => [ qw(file) ],
         get_settings => [ qw(index|indices_list|OPTIONAL name|names_list|OPTIONAL) ],
         put_settings => [ qw(settings_hash index|indices_list|OPTIONAL) ],
         set_index_number_of_replicas => [ qw(index|indices_list number) ],
         set_index_refresh_interval => [ qw(index|indices_list number) ],
         get_index_number_of_replicas => [ qw(index|indices) ],
         get_index_refresh_interval => [ qw(index|indices_list) ],
         get_index_number_of_shards => [ qw(index|indices_list) ],
         delete_template => [ qw(name) ],
         is_index_exists => [ qw(index) ],
         is_type_exists => [ qw(index type) ],
         is_document_exists => [ qw(index type document) ],
         refresh_index => [ qw(index) ],
         export_as_csv => [ qw(index size|OPTIONAL) ],
         import_from_csv => [ qw(input_csv index|OPTIONAL type|OPTIONAL size|OPTIONAL) ],
         get_stats_process => [ ],
         get_process => [ ],
         get_cluster_state => [ ],
         get_cluster_health => [ ],
         get_cluster_settings => [ ],
         put_cluster_settings => [ qw(settings) ],
         count_green_shards => [ ],
         count_yellow_shards => [ ],
         count_red_shards => [ ],
         list_green_shards => [ ],
         list_yellow_shards => [ ],
         list_red_shards => [ ],
         count_shards => [ ],
         list_datatypes => [ ],
         get_hits_total => [ ],
         disable_shard_allocation => [ ],
         enable_shard_allocation => [ ],
         flush_synced => [ ],
         create_snapshot_repository => [ qw(body repository_name|OPTIONAL) ],
         create_shared_fs_snapshot_repository => [ qw(location repository_name|OPTIONAL) ],
         get_snapshot_repositories => [ ],
         get_snapshot_status => [ ],
         delete_snapshot_repository => [ qw(repository_name) ],
         create_snapshot => [ qw(snapshot_name|OPTIONAL repository_name|OPTIONAL body|OPTIONAL) ],
         create_snapshot_for_indices => [ qw(indices snapshot_name|OPTIONAL repository_name|OPTIONAL) ],
         is_snapshot_finished => [ ],
         get_snapshot_state => [ ],
         get_snapshot => [ qw(snapshot_name|OPTIONAL repository_name|OPTIONAL) ],
         delete_snapshot => [ qw(snapshot_name repository_name) ],
         restore_snapshot => [ qw(snapshot_name repository_name body|OPTIONAL) ],
         restore_snapshot_for_indices => [ qw(indices snapshot_name repository_name) ],
      },
      require_modules => {
         'Metabrik::String::Base64' => [ ],
         'Metabrik::String::Json' => [ ],
         'Metabrik::File::Csv' => [ ],
         'Metabrik::File::Json' => [ ],
         'Metabrik::File::Raw' => [ ],
         'Data::Dump' => [ ],
         'Search::Elasticsearch' => [ ],
      },
   };
}

sub brik_preinit {
   my $self = shift;

   eval("use Search::Elasticsearch;");
   if ($Search::Elasticsearch::VERSION < 5) {
      $self->log->error("brik_preinit: please upgrade Search::Elasticsearch module with: ".
         "run perl::module install Search::Elasticsearch");
   }

   return $self->SUPER::brik_preinit;
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

   my $timeout = $self->rtimeout;

   my $nodes_str = join('|', @$nodes);
   $self->log->verbose("open: using nodes [$nodes_str]");

   #
   # Timeout description here:
   #
   # Search::Elasticsearch::Role::Cxn
   #

   my $es = Search::Elasticsearch->new(
      nodes => $nodes,
      cxn_pool => $cxn_pool,
      timeout => $timeout,
      max_retries => $self->try,
      retry_on_timeout => 1,
      sniff_timeout => $self->sniff_rtimeout,
   );
      #request_timeout => 10,  # seconds
      #ping_timeout => 5,  # seconds
      #dead_timeout => 60,  # seconds
      #max_dead_timeout => 3600,  # seconds
      #sniff_request_timeout => 5, # seconds
   if (! defined($es)) {
      return $self->log->error("open: failed");
   }

   $self->_es($es);

   return $nodes;
}

#
# Search::Elasticsearch::Client::5_0::Bulk
#
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

   my $es = $self->_es;

   my $bulk = $es->bulk_helper(
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

   my $version = $self->version or return;
   if ($version ge "5.0.0") {
      return $self->log->error("open_scroll_scan_mode: Command not supported for ES version ".
         "$version, try open_scroll Command instead");
   }

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

   my $es = $self->_es;

   my $scroll = $es->scroll_helper(
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

#
# Search::Elasticsearch::Client::5_0::Scroll
#
sub open_scroll {
   my $self = shift;
   my ($index, $size, $nodes, $cxn_pool) = @_;

   my $version = $self->version or return;
   if ($version lt "5.0.0") {
      return $self->log->error("open_scroll: Command not supported for ES version ".
         "$version, try open_scroll_scan_mode Command instead");
   }

   $index ||= $self->index;
   $size ||= $self->size;
   $nodes ||= $self->nodes;
   $cxn_pool ||= $self->cxn_pool;
   $self->brik_help_run_undef_arg('open_scroll', $index) or return;
   $self->brik_help_run_undef_arg('open_scroll', $size) or return;
   $self->brik_help_run_undef_arg('open_scroll', $nodes) or return;
   $self->brik_help_run_undef_arg('open_scroll', $cxn_pool) or return;
   $self->brik_help_run_invalid_arg('open_scroll', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('open_scroll', $nodes) or return;

   my $timeout = $self->rtimeout;

   $self->open($nodes, $cxn_pool) or return;

   my $es = $self->_es;

   #
   # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html
   #
   my $scroll = $es->scroll_helper(
      scroll => "${timeout}s",
      index => $index,
      size => $size,
      body => {
         sort => [ qw(_doc) ],
      },
   );
   if (! defined($scroll)) {
      return $self->log->error("open_scroll: failed");
   }

   $self->_scroll($scroll);

   $self->log->info("open_scroll: opened with size [$size] and timeout [${timeout}s]");

   return $nodes;
}

#
# Search::Elasticsearch::Client::5_0::Scroll
#
sub close_scroll {
   my $self = shift;

   my $scroll = $self->_scroll;
   if (! defined($scroll)) {
      return 1;
   }

   $scroll->finish;
   $self->_scroll(undef);

   return 1;
}

sub total_scroll {
   my $self = shift;

   my $scroll = $self->_scroll;
   $self->brik_help_run_undef_arg('open_scroll', $scroll) or return;

   my $total;
   eval {
      $total = $scroll->total;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("total_scroll: failed with: [$@]");
   }

   return $total;
}

sub next_scroll {
   my $self = shift;

   my $scroll = $self->_scroll;
   $self->brik_help_run_undef_arg('open_scroll', $scroll) or return;

   my $next;
   eval {
      $next = $scroll->next;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("next_scroll: failed with: [$@]");
   }

   return $next;
}

sub index_document {
   my $self = shift;
   my ($doc, $index, $type, $id) = @_;

   my $es = $self->_es;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('index_document', $doc) or return;
   $self->brik_help_run_invalid_arg('index_document', $doc, 'HASH') or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my %args = (
      index => $index,
      type => $type,
      body => $doc,
   );
   if (defined($id)) {
      $args{id} = $id;
   }

   my $r;
   eval {
      $r = $es->index(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("index_document: index failed for index [$index]: [$@]");
   }

   return $r;
}

sub index_bulk {
   my $self = shift;
   my ($doc, $index, $type, $id) = @_;

   my $bulk = $self->_bulk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;
   $self->brik_help_run_undef_arg('index_bulk', $doc) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my %args = (
      source => $doc,
   );
   if (defined($id)) {
      $args{id} = $id;
   }

   my $r;
   eval {
      $r = $bulk->index(\%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("index_bulk: index failed for index [$index]: [$@]");
   }

   return $r;
}

sub bulk_flush {
   my $self = shift;

   my $bulk = $self->_bulk;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;

   my $r;
   eval {
      $r = $bulk->flush;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("bulk_flush: flush failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct
# Search::Elasticsearch::Client::5_0::Direct
#
sub count {
   my $self = shift;
   my ($index, $type) = @_;

   my $es = $self->_es;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my %args = ();
   if (defined($index) && $index ne '*') {
      $args{index} = $index;
   }
   if (defined($type) && $type ne '*') {
      $args{type} = $type;
   }

   #$args{body} = {
      #query => {
         #match => { title => 'Elasticsearch clients' },
      #},
   #}

   my $r;
   my $version = $self->version or return;
   if ($version ge "5.0.0") {
      eval {
         $r = $es->count(%args);
      };
   }
   else {
      eval {
         $r = $es->search(
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
   }
   if ($@) {
      chomp($@);
      return $self->log->error("count: count failed for index [$index]: [$@]");
   }

   if ($version ge "5.0.0") {
      if (exists($r->{count})) {
         return $r->{count};
      }
   }
   elsif (exists($r->{hits}) && exists($r->{hits}{total})) {
      return $r->{hits}{total};
   }

   return $self->log->error("count: nothing found");
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/full-text-queries.html
# https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html
#
# Example: my $q = { query => { term => { ip => "192.168.57.19" } } }
#
sub query {
   my $self = shift;
   my ($query, $index, $type) = @_;

   my $es = $self->_es;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('query', $query) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;
   $self->brik_help_run_invalid_arg('query', $query, 'HASH') or return;

   my $timeout = $self->rtimeout;

   my %args = (
      index => $index,
      from => $self->from,
      size => $self->size,
      body => $query,
      #timeout => $timeout, # XXX: does not work
   );

   if ($type ne '*') {
      $args{type} = $type;
   }

   my $r;
   eval {
      $r = $es->search(%args);
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

   my $es = $self->_es;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_from_id', $id) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my $r;
   eval {
      $r = $es->get(
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
   my ($query, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('www_search', $query) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my $from = $self->from;
   my $size = $self->size;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $nodes = $self->nodes;
   for my $node (@$nodes) {
      # http://localhost:9200/INDEX/TYPE/_search/?size=SIZE&q=QUERY
      my $url = "$node/$index";
      if ($type ne '*') {
         $url .= "/$type";
      }
      $url .= "/_search/?from=$from&size=$size&q=".$query;

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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_index', $index) or return;
   $self->brik_help_run_invalid_arg('delete_index', $index, 'ARRAY', 'SCALAR') or return;

   my %args = (
      index => $index,
   );

   my $r;
   eval {
      $r = $es->indices->delete(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_index: delete failed for index [$index]: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
sub show_indices {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->indices;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_indices: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_indices: nothing returned, no index?");
   }

   return \@lines;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
sub show_nodes {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->nodes;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_nodes: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_nodes: nothing returned, no nodes?");
   }

   return \@lines;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
sub show_health {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->health;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_health: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_health: nothing returned, no recovery?");
   }

   return \@lines;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
sub show_recovery {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->recovery;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_recovery: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_recovery: nothing returned, no index?");
   }

   return \@lines;
}

sub list_indices {
   my $self = shift;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      push @indices, $_->{index};
   }

   return [ sort { $a cmp $b } @indices ];
}

sub get_indices {
   my $self = shift;

   my $lines = $self->show_indices or return;
   if (@$lines == 0) {
      $self->log->warning("get_indices: no index found");
      return [];
   }

   #
   # Format depends on ElasticSearch version. We try to detect the format.
   #
   # 5.0.0:
   # "yellow open www-2016-08-14 BmNE9RaBRSCKqB5Oe8yZcw 5 1  146 0 251.8kb 251.8kb"
   #
   my @indices = ();
   for (@$lines) {
      my @t = split(/\s+/);
      if (@t == 10) {  # Version 5.0.0
         my $color = $t[0];
         my $state = $t[1];
         my $index = $t[2];
         my $id = $t[3];
         my $shards = $t[4];
         my $replicas = $t[5];
         my $count = $t[6];
         my $count2 = $t[7];
         my $total_size = $t[7];
         my $size = $t[8];
         push @indices, {
            color => $color,
            state => $state,
            index => $index,
            id => $id,
            shards => $shards,
            replicas => $replicas,
            count => $count,
            total_size => $total_size,
            size => $size,
         };
      }
      elsif (@t == 9) {
         my $index = $t[2];
         push @indices, {
            index => $index,
         };
      }
      elsif (@t == 8) {
         my $index = $t[1];
         push @indices, {
            index => $index,
         };
      }
   }

   return \@indices;
}

sub get_index {
   my $self = shift;
   my ($index) = @_;
 
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index', $index) or return;
   $self->brik_help_run_invalid_arg('get_index', $index, 'ARRAY', 'SCALAR') or return;

   my $r;
   eval {
      $r = $es->indices->get(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_index: get failed for index [$index]: [$@]");
   }

   return $r;
}

sub list_indices_version {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('list_indices_version', $index) or return;
   $self->brik_help_run_invalid_arg('list_indices_version', $index, 'ARRAY', 'SCALAR') or return;

   my $r = $self->get_index($index) or return;

   my @list = ();
   for my $this (keys %$r) {
      my $name = $this;
      my $version = $r->{$this}{settings}{index}{version}{created};
      push @list, {
         index => $name,
         version => $version,
      };
   }

   return \@list;
}

sub open_index {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('open_index', $index) or return;
   $self->brik_help_run_invalid_arg('open_index', $index, 'ARRAY', 'SCALAR') or return;

   my $r;
   eval {
      $r = $es->indices->open(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("open_index: failed: [$@]");
   }

   return $r;
}

sub close_index {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('close_index', $index) or return;
   $self->brik_help_run_invalid_arg('close_index', $index, 'ARRAY', 'SCALAR') or return;

   my $r;
   eval {
      $r = $es->indices->close(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("close_index: failed: [$@]");
   }

   return $r;
}

sub get_aliases {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->indices->get_aliases;
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
   if ($index ne '*') {
      if (exists($r->{$index}) && exists($r->{$index}{mappings})) {
         return $r->{$index}{mappings};
      }
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub create_index {
   my $self = shift;
   my ($index, $shards_count) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('create_index', $index) or return;
         
   my $r;
   eval {
      $r = $es->indices->create(
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('create_index_with_mappings', $index) or return;
   $self->brik_help_run_undef_arg('create_index_with_mappings', $mappings) or return;
   $self->brik_help_run_invalid_arg('create_index_with_mappings', $mappings, 'HASH') or return;

   my $r;
   eval {
      $r = $es->indices->create(
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

# GET http://localhost:9200/
sub info {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('info', $nodes) or return;
   $self->brik_help_run_invalid_arg('info', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('info', $nodes) or return;

   my $first = $nodes->[0];

   $self->get($first) or return;

   return $self->content;
}

sub version {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('version', $nodes) or return;
   $self->brik_help_run_invalid_arg('version', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('version', $nodes) or return;

   my $first = $nodes->[0];

   $self->get($first) or return;
   my $content = $self->content or return;

   return $content->{version}{number};
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub get_templates {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->indices->get_template;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_templates: failed: [$@]");
   }

   return $r;
}

sub list_templates {
   my $self = shift;

   my $content = $self->get_templates or return;

   return [ sort { $a cmp $b } keys %$content ];
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub get_template {
   my $self = shift;
   my ($template) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_template', $template) or return;

   my $r;
   eval {
      $r = $es->indices->get_template(
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_template', $name) or return;
   $self->brik_help_run_undef_arg('put_template', $template) or return;
   $self->brik_help_run_invalid_arg('put_template', $template, 'HASH') or return;

   my $r;
   eval {
      $r = $es->indices->put_template(
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

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
      $r = $es->indices->get_settings(%args);
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
# XXX: should be renamed to put_index_settings
#
sub put_settings {
   my $self = shift;
   my ($settings, $indices) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
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
      $r = $es->indices->put_settings(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_settings: failed: [$@]");
   }

   return $r;
}

sub set_index_number_of_replicas {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('set_index_number_of_replicas', $indices) or return;
   $self->brik_help_run_invalid_arg('set_index_number_of_replicas', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = { number_of_replicas => $number };

   return $self->put_settings($settings, $indices);
}

sub set_index_refresh_interval {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('set_index_refresh_interval', $indices) or return;
   $self->brik_help_run_invalid_arg('set_index_refresh_interval', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = { refresh_interval => $number };

   return $self->put_settings($settings, $indices);
}

sub get_index_number_of_replicas {
   my $self = shift;
   my ($indices) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_number_of_replicas', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_number_of_replicas', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      $indices{$_} = $settings->{$_}{settings}{index}{number_of_replicas};
   }

   return \%indices;
}

sub get_index_refresh_interval {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_refresh_interval', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_refresh_interval', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      $indices{$_} = $settings->{$_}{settings}{index}{refresh_interval};
   }

   return \%indices;
}

sub get_index_number_of_shards {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_number_of_shards', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_number_of_shards', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      $indices{$_} = $settings->{$_}{settings}{index}{number_of_shards};
   }

   return \%indices;
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub delete_template {
   my $self = shift;
   my ($name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_template', $name) or return;

   my $r;
   eval {
      $r = $es->indices->delete_template(
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('is_index_exists', $index) or return;

   my $r;
   eval {
      $r = $es->indices->exists(
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('is_type_exists', $index) or return;
   $self->brik_help_run_undef_arg('is_type_exists', $type) or return;

   my $r;
   eval {
      $r = $es->indices->exists_type(
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $index) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $type) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $document) or return;
   $self->brik_help_run_invalid_arg('is_document_exists', $document, 'HASH') or return;

   my $r;
   eval {
      $r = $es->exists(
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

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('refresh_index', $index) or return;

   my $r;
   eval {
      $r = $es->indices->refresh(
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
   my ($index, $size) = @_;

   $size ||= 10_000;
   $self->brik_help_run_undef_arg('export_as_csv', $index) or return;
   $self->brik_help_run_undef_arg('export_as_csv', $size) or return;

   my $max = $self->max;

   my $scroll;
   my $version = $self->version or return;
   if ($version lt "5.0.0") {
      $scroll = $self->open_scroll_scan_mode($index, $size) or return;
   }
   else {
      $scroll = $self->open_scroll($index, $size) or return;
   }

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->separator(',');
   $fc->escape('\\');
   $fc->append(1);
   $fc->first_line_is_header(0);
   $fc->write_header(1);
   $fc->use_quoting(1);

   my $total = $self->total_scroll;
   $self->log->info("export_as_csv: total [$total]");

   local $Data::Dump::INDENT = "";    # No indentation shorten length
   local $Data::Dump::TRY_BASE64 = 0; # Never encode in base64

   my $h = {};
   my %types = ();
   my $processed = 0;
   my $start = time();
   while (my $this = $self->next_scroll) {
      my $id = $this->{_id};
      my $doc = $this->{_source};
      my $type = $this->{_type};
      if (! exists($types{$type})) {
         $types{$type}{header} = [ '_id', sort { $a cmp $b } keys %$doc ];
         $types{$type}{output} = "$index:$type.csv";
         $self->log->info("export_as_csv: exporting to file [$index:$type.csv] ".
            "for new type [$type], using chunk size of [$size]");
      }

      $h->{_id} = $id;

      for my $k (keys %$doc) {
         if (ref($doc->{$k})) {
            my $s = Data::Dump::dump($doc->{$k});
            $s =~ s{\n}{}g;
            $h->{$k} = 'BASE64:'.$sb->encode($s);
         }
         else {
            $h->{$k} = $doc->{$k};
         }
      }

      $fc->header($types{$type}{header});
      my $r = $fc->write([ $h ], $types{$type}{output});
      if (!defined($r)) {
         $self->log->warning("export_as_csv: unable to process entry, skipping");
         next;
      }

      # Log a status sometimes.
      if (! (++$processed % 100_000)) {
         my $now = time();
         $self->log->info("export_as_csv: fetched [$processed/$total] elements in ".
            ($now - $start)." second(s)");
         $start = time();
      }

      # Limit export to specified maximum
      if ($max > 0 && $processed >= $max) {
         $self->log->info("export_as_csv: max export reached [$processed], stopping");
         last;
      }
   }

   $self->close_scroll;

   return $processed;
}

sub import_from_csv {
   my $self = shift;
   my ($input_csv, $index, $type, $size) = @_;

   $size ||= 10_000;
   $self->brik_help_run_undef_arg('import_from_csv', $input_csv) or return;
   $self->brik_help_run_file_not_found('import_from_csv', $input_csv) or return;

   # If index and/or types are not defined, we try to get them from input filename
   if (! defined($index) || ! defined($type)) {
      # Example: index-DATE:type.csv
      if ($input_csv =~ m{^(.+):(.+)\.csv(?:.*)?$}) {
         my ($this_index, $this_type) = $input_csv =~ m{^(.+):(.+)\.csv(?:.*)?$};
         $index ||= $this_index;
         $type ||= $this_type;
      }
   }

   # Verify it has not been indexed yet
   my $done = "$input_csv.imported";
   if (-f $done) {
      $self->log->info("import_from_csv: import already done for file [$input_csv]");
      return 0;
   }

   # And default to Attributes if guess failed.
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   if ($index eq '*') {
      return $self->log->error("import_from_csv: cannot import to invalid index [$index]");
   }
   if ($type eq '*') {
      return $self->log->error("import_from_csv: cannot import to invalid type [$type]");
   }

   $self->log->debug("input [$input_csv]");
   $self->log->debug("index [$index]");
   $self->log->debug("type [$type]");

   my $count_before = 0;
   if ($self->is_index_exists($index)) {
      $count_before = $self->count($index, $type);
      if (! defined($count_before)) {
         return;
      }
      $self->log->info("import_from_csv: current index count is [$count_before]");
   }

   my $max = $self->max;

   $self->open_bulk_mode($index, $type) or return;

   $self->log->info("import_from_csv: importing file [$input_csv] to index [$index] ".
      "with type [$type], using chunk size of [$size]");

   my $fr = Metabrik::File::Raw->new_from_brik_init($self) or return;
   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->separator(',');
   $fc->escape('\\');
   $fc->first_line_is_header(1);

   my $start = time();
   my $speed_settings = {};
   my $imported = 0;
   my $first = 1;
   my $read = 0;
   while (my $this = $fc->read_next($input_csv)) {
      $read++;

      my $h = {};
      my $id = $this->{_id};
      delete $this->{_id};
      for my $key (keys %$this) {
         my $value = $this->{$key};
         if ($value =~ m{^BASE64:(.*)$}) {  # An OBJECT is waiting to be decoded
            my $s = $sb->decode($1);
            $h->{$key} = eval($s);
         }
         else {  # Non-encoded value
            $h->{$key} = $value;
         }
      }

      my $r = $self->index_bulk($h, $index, $type, $id);
      if (! defined($r)) {
         $self->log->error("import_from_csv: bulk processing failed for index [$index] at ".
            "read [$read], skipping");
         next;
      }

      # Gather index settings, and set values for speed.
      # We don't do it earlier, cause we need index to be created,
      # and it should have been done from index_bulk Command.
      if ($first && $self->is_index_exists($index)) {
         $speed_settings = {
            number_of_replicas => 0,
            refresh_interval => -1,
         };
         $self->put_settings($speed_settings, $index);
         $first = 0;
      }

      # Log a status sometimes.
      if (! (++$imported % 100_000)) {
         my $now = time();
         $self->log->info("import_from_csv: imported [$imported] entries in ".
            ($now - $start)." second(s)");
         $start = time();
      }

      # Limit import to specified maximum
      if ($max > 0 && $imported >= $max) {
         $self->log->info("import_from_csv: max import reached [$imported], stopping");
         last;
      }
   }

   $self->bulk_flush or return;

   $self->refresh_index($index) or return;

   my $count_current = $self->count($index, $type) or return;
   $self->log->info("import_from_csv: after index count is [$count_current]");

   my $result = {
      read => $read,
      imported => $imported,
      skipped => $read - $imported,
      previous_count => $count_before,
      current_count => $count_current,
   };

   # Say the file has been processed, and put resulting stats.
   $fr->write($result, $done) or return;

   return $result;
}

#
# http://localhost:9200/_nodes/stats/process?pretty
#
# Search::Elasticsearch::Client::2_0::Direct::Nodes
#
sub get_stats_process {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->nodes->stats(
         metric => [ qw(process) ],
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_stats_process: failed: [$@]");
   }

   return $r;
}

#
# curl http://localhost:9200/_nodes/process?pretty
#
# Search::Elasticsearch::Client::2_0::Direct::Nodes
#
sub get_process {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->nodes->info(
         metric => [ qw(process) ],
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_process: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub get_cluster_state {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cluster->state;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_cluster_state: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub get_cluster_health {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cluster->health;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_cluster_health: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub get_cluster_settings {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cluster->get_settings;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_cluster_settings: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub put_cluster_settings {
   my $self = shift;
   my ($settings) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_cluster_settings', $settings) or return;
   $self->brik_help_run_invalid_arg('put_cluster_settings', $settings, 'HASH') or return;

   my %args = (
      body => $settings,
   );

   my $r;
   eval {
      $r = $es->cluster->put_settings(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_cluster_settings: failed: [$@]");
   }

   return $r;
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

sub count_shards {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count_red = 0;
   my $count_yellow = 0;
   my $count_green = 0;
   for (@$get) {
      if (/^\s*red\s+/) {
         $count_red++;
      }
      elsif (/^\s*yellow\s+/) {
         $count_yellow++;
      }
      elsif (/^\s*green\s+/) {
         $count_green++;
      }
   }

   return {
      red => $count_red,
      yellow => $count_yellow,
      green => $count_green,
   };
}

sub list_green_shards {
   my $self = shift;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      if ($_->{color} eq 'green') {
         push @indices, $_->{index};
      }
   }

   return \@indices;
}

sub list_yellow_shards {
   my $self = shift;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      if ($_->{color} eq 'yellow') {
         push @indices, $_->{index};
      }
   }

   return \@indices;
}

sub list_red_shards {
   my $self = shift;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      if ($_->{color} eq 'red') {
         push @indices, $_->{index};
      }
   }

   return \@indices;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-types.html
#
sub list_datatypes {
   my $self = shift;

   return {
      core => [ qw(string long integer short byte double float data boolean binary) ],
   };
}

#
# Return total hits for last www_search
#
sub get_hits_total {
   my $self = shift;

   # Retrieve data stored in the $RUN Variable from Context
   my $run = $self->context->do('$RUN');
   if (ref($run) eq 'HASH') {
      if (exists($run->{hits}) && exists($run->{hits}{total})) {
         return $run->{hits}{total};
      }
   }

   return $self->log->error("get_hits_total: last Command not compatible");
}

sub disable_shard_allocation {
   my $self = shift;

   my $settings = {
      persistent => {
         'cluster.routing.allocation.enable' => 'none',
      }
   };

   return $self->put_cluster_settings($settings);
}

sub enable_shard_allocation {
   my $self = shift;

   my $settings = {
      persistent => { 
         'cluster.routing.allocation.enable' => 'all',
      }
   };

   return $self->put_cluster_settings($settings);
}

sub flush_synced {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->indices->flush_synced;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("flush_synced: failed: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html
#
# run client::elasticsearch create_snapshot_repository myrepo 
#      "{ type => 'fs', settings => { compress => 'true', location => '/path/' } }"
#
# You have to set path.repo in elasticsearch.yml like:
# path.repo: ["/home/gomor/es-backups"]
#
# Search::Elasticsearch::Client::2_0::Direct::Snapshot
#
sub create_snapshot_repository {
   my $self = shift;
   my ($body, $repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('create_snapshot_repository', $body) or return;

   $repository_name ||= 'repository';

   my %args = (
      repository => $repository_name,
      body => $body,
   );

   my $r;
   eval {
      $r = $es->snapshot->create_repository(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_snapshot_repository: failed: [$@]");
   }

   return $r;
}

sub create_shared_fs_snapshot_repository {
   my $self = shift;
   my ($location, $repository_name) = @_;

   $repository_name ||= 'repository';
   $self->brik_help_run_undef_arg('create_shared_fs_snapshot_repository', $location) or return;

   if ($location !~ m{^/}) {
      return $self->log->error("create_shared_fs_snapshot_repository: you have to give ".
         "a full directory path, this one is invalid [$location]");
   }

   my $body = {
      type => 'fs',
      settings => {
         compress => 'true',
         location => $location,
      },
   };

   return $self->create_snapshot_repository($body, $repository_name);
}

#
# Search::Elasticsearch::Client::2_0::Direct::Snapshot
#
sub get_snapshot_repositories {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->snapshot->get_repository;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_snapshot_repositories: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Snapshot
#
sub get_snapshot_status {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->snapshot->status;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_snapshot_status: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Snapshot
#
sub create_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name, $body) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';

   my %args = (
      repository => $repository_name,
      snapshot => $snapshot_name,
   );
   if (defined($body)) {
      $args{body} = $body;
   }

   my $r;
   eval {
      $r = $es->snapshot->create(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_snapshot: failed: [$@]");
   }

   return $r;
}

sub create_snapshot_for_indices {
   my $self = shift;
   my ($indices, $snapshot_name, $repository_name) = @_;

   $self->brik_help_run_undef_arg('create_snapshot_for_indices', $indices) or return;
   $self->brik_help_run_invalid_arg('create_snapshot_for_indices', $indices, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('create_snapshot_for_indices', $indices) or return;

   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';

   my $body = {
      indices => $indices,
   };

   return $self->create_snapshot($snapshot_name, $repository_name, $body);
}

sub is_snapshot_finished {
   my $self = shift;

   my $status = $self->get_snapshot_status or return;

   if (@{$status->{snapshots}} == 0) {
      return 1;
   }

   return 0;
}

sub get_snapshot_state {
   my $self = shift;

   if ($self->is_snapshot_finished) {
      return $self->log->info("get_snapshot_state: is already finished");
   }

   my $status = $self->get_snapshot_status or return;

   my @indices_done = ();
   my @indices_not_done = ();

   my $list = $status->{snapshots};
   for my $snapshot (@$list) {
      my $indices = $snapshot->{indices};
      for my $index (@$indices) {
         my $done = $index->{shards_stats}{done};
         if ($done) {
            push @indices_done, $index;
         }
         else {
            push @indices_not_done, $index;
         }
      }
   }

   return { done => \@indices_done, not_done => \@indices_not_done };
}

sub verify_snapshot_repository {
}

sub delete_snapshot_repository {
   my $self = shift;
   my ($repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_snapshot_repository', $repository_name) or return;

   my $r;
   eval {
      $r = $es->snapshot->delete_repository(
         repository => $repository_name,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_snapshot_repository: failed: [$@]");
   }

   return $r;
}

sub get_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';

   my $r;
   eval {
      $r = $es->snapshot->get(
         repository => $repository_name,
         snapshot => $snapshot_name,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_snapshot: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::5_0::Direct::Snapshot
#
sub delete_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_snapshot', $snapshot_name) or return;
   $self->brik_help_run_undef_arg('delete_snapshot', $repository_name) or return;

   my $timeout = $self->rtimeout;

   my $r;
   eval {
      $r = $es->snapshot->delete(
         repository => $repository_name,
         snapshot => $snapshot_name,
         master_timeout => "${timeout}s",
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_snapshot: failed: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html
#
sub restore_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name, $body) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('restore_snapshot', $snapshot_name) or return;
   $self->brik_help_run_undef_arg('restore_snapshot', $repository_name) or return;

   my %args = (
      repository => $repository_name,
      snapshot => $snapshot_name,
   );
   if (defined($body)) {
      $args{body} = $body;
   }

   my $r;
   eval {
      $r = $es->snapshot->restore(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("restore_snapshot: failed: [$@]");
   }

   return $r;
}

sub restore_snapshot_for_indices {
   my $self = shift;
   my ($indices, $snapshot_name, $repository_name) = @_;

   $self->brik_help_run_undef_arg('restore_snapshot_for_indices', $indices) or return;
   $self->brik_help_run_undef_arg('restore_snapshot_for_indices', $snapshot_name) or return;
   $self->brik_help_run_undef_arg('restore_snapshot_for_indices', $repository_name) or return;
   $self->brik_help_run_invalid_arg('restore_snapshot_for_indices', $indices, 'ARRAY')
     or return;
   $self->brik_help_run_empty_array_arg('restore_snapshot_for_indices', $indices) or return;

   my $body = {
      indices => $indices,
   };

   return $self->restore_snapshot($snapshot_name, $repository_name, $body);
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
