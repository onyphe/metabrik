#
# $Id$
#
# forensic::sysmon Brik
#
package Metabrik::Forensic::Sysmon;
use strict;
use warnings;

use base qw(Metabrik::Client::Elasticsearch::Query);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         nodes => [ qw(node_list) ], # Inherited
         index => [ qw(index) ],     # Inherited
         type => [ qw(type) ],       # Inherited
         filter_user => [ qw(user) ],
         filter_session => [ qw(session) ],
         filter_computer_name => [ qw(name) ],
      },
      attributes_default => {
         index => 'winlogbeat-*',
         type => 'wineventlog',
      },
      commands => {
         create_client => [ ],
         reset_client => [ ],
         query => [ qw(query index|OPTIONAL type|OPTIONAL) ],
         get_event_id => [ qw(event_id index|OPTIONAL type|OPTIONAL) ],
         get_process_create => [ ],
         get_file_creation_time_changed => [ ],
         get_network_connection_detected => [ ],
         get_sysmon_service_state_changed => [ ],
         get_process_terminated => [ ],
         get_driver_loaded => [ ],
         get_image_loaded => [ ],
         get_create_remote_thread => [ ],
         get_raw_access_read_detected => [ ],
         get_process_accessed => [ ],
         get_file_created => [ ],
         get_registry_object_added_or_deleted => [ ],
         get_registry_value_set => [ ],
         get_sysmon_config_state_changed => [ ],
         ps => [ ],
         ps_tree => [ ],
         ps_image_loaded => [ ],
         ps_driver_loaded => [ ],
         ps_parent_image => [ ],
         ps_target_filename_created => [ ],
         ps_target_filename_changed => [ ],
         ps_target_image => [ ],
         ps_network_connections => [ ],
         ps_registry_object_added_or_deleted => [ ],
         ps_registry_value_set => [ ],
         ps_target_process_accessed => [ ],
         list_users => [ ],
         list_sessions => [ ],
         list_computer_names => [ ],
         list_domains => [ ],
      },
      require_modules => {
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

#
#  1: PROCESS CREATION
#  2: FILE CREATION TIME RETROACTIVELY CHANGED IN THE FILESYSTEM
#  3: NETWORK CONNECTION INITIATED
#  4: RESERVED FOR SYSMON STATUS MESSAGES
#  5: PROCESS ENDED
#  6: DRIVER LOADED INTO KERNEL
#  7: DLL (IMAGE) LOADED BY PROCESS
#  8: REMOTE THREAD CREATED
#  9: RAW DISK ACCESS
# 10: INTER-PROCESS ACCESS
# 11: FILE CREATED
# 12: REGISTRY MODIFICATION
# 13: REGISTRY MODIFICATION
# 14: REGISTRY MODIFICATION
# 15: ALTERNATE DATA STREAM CREATED
# 16: SYSMON CONFIGURATION CHANGE
# 17: PIPE CREATED
# 18: PIPE CONNECTED
#
sub get_event_id {
   my $self = shift;
   my ($event_id, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('get_event_id', $event_id) or return;

   my $user = $self->filter_user;
   my $name = $self->filter_computer_name;
   my $session = $self->filter_session;

   my $from = 0;
   my $size = 10_000;
   my $q = {
      from => $from,
      size => $size,
      sort => [
         { '@timestamp' => { order => "desc" } },
      ],
      query => {
         bool => {
            must => [
               { term => { event_id => $event_id } },
               { term => { source_name => 'Microsoft-Windows-Sysmon' } }
            ]
         }
      }
   };

   if (defined($user)) {
      push @{$q->{query}{bool}{must}}, { term => { 'event_data.User' => $user } };
   }
   if (defined($name)) {
      push @{$q->{query}{bool}{must}}, { term => { 'computer_name' => $name } };
   }
   if (defined($session)) {
      push @{$q->{query}{bool}{must}},
         { term => { 'event_data.LogonGuid' => $session } };
   }

   my $r = $self->query($q, $index, $type);
   my $hits = $self->get_query_result_hits($r);

   my @list = ();
   for my $this (@$hits) {
      $this = $this->{_source};
      push @list, {
         '@timestamp' => $this->{'@timestamp'},
         event_id => $this->{event_id},
         event_data => $this->{event_data},
         computer_name => $this->{computer_name},
         process_id => $this->{process_id},
         provider_guid => $this->{provider_guid},
         record_number => $this->{record_number},
         thread_id => $this->{thread_id},
         task => $this->{task},
         user => $this->{user},
         version => $this->{version},
      };
   }

   return \@list;
}

sub get_process_create {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(1, $index, $type);
}

sub get_file_creation_time_changed {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(2, $index, $type);
}

sub get_network_connection_detected {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(3, $index, $type);
}

sub get_sysmon_service_state_changed {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(4, $index, $type);
}

sub get_process_terminated {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(5, $index, $type);
}

sub get_driver_loaded {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(6, $index, $type);
}

sub get_image_loaded {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(7, $index, $type);
}

sub get_create_remote_thread {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(8, $index, $type);
}

sub get_raw_access_read_detected {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(9, $index, $type);
}

sub get_process_accessed {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(10, $index, $type);
}

sub get_file_created {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(11, $index, $type);
}

sub get_registry_object_added_or_deleted {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(12, $index, $type);
}

sub get_registry_value_set {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(13, $index, $type);
}

# XXX: 14
# XXX: 15

sub get_sysmon_config_state_changed {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;

   return $self->get_event_id(16, $index, $type);
}

sub _read_hashes {
   my $self = shift;
   my ($hashes) = @_;

   # SHA1=99052FD84F00B5279E304798F5C2675A1C201146,
   # MD5=70C298C6990F5A0BBF60F5C035BAA0B9,
   # SHA256=D4E8D0DCAF077A4FECA5C974EA430A2AD1FE3118F14512D662B26D8D09CD3A08,
   # IMPHASH=089C9EDE118FC9F36EEBA769ACA5EA16
   my $h = {};
   my @hash_list = split(/,/, $hashes);
   for (@hash_list) {
      if (m{^.+=.+$}) {
         my ($k, $v) = split(/=/, $_);
         if (defined($k) && defined($v)) {
            $h->{lc($k)} = lc($v);
         }
      }
   }

   return $h;
}

sub ps {
   my $self = shift;

   my $r = $self->get_process_create or return;

   my @ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
      my $command_line = $this->{event_data}{CommandLine};
      my $parent_process_id = $this->{event_data}{ParentProcessId};
      my $parent_image = $this->{event_data}{ParentImage};
      my $parent_command_line = $this->{event_data}{ParentCommandLine};

      my $new = {
         process_id => $process_id,
         image => $image,
         command_line => $command_line,
         parent_process_id => $parent_process_id,
         parent_image => $parent_image,
         parent_command_line => $parent_command_line,
      };

      my $hashes = $this->{event_data}{Hashes};
      my $h = $self->_read_hashes($hashes);
      for my $k (keys %$h) {
         $new->{$k} = $h->{$k};
      }

      push @ps, $new;
   }

   return \@ps;
}

sub ps_tree {
   my $self = shift;

   my $ps = $self->ps or return;

   my @ps = ();

   return \@ps;
}

sub _dedup_values {
   my $self = shift;
   my ($data) = @_;

   for my $k1 (keys %$data) {
      for my $k2 (keys %{$data->{$k1}}) {
         my $ary = $data->{$k1}{$k2};
         if (ref($ary) eq 'ARRAY') {
            my %uniq = map { $_ => 1 } @$ary;
            $data->{$k1}{$k2} = [ sort { $a cmp $b } keys %uniq ];
         }
      }
   }

   my @list = ();
   for my $k1 (keys %$data) {
      push @list, { image => $k1, %{$data->{$k1}} };
   }

   return \@list;
}

sub ps_image_loaded {
   my $self = shift;

   my $r = $self->get_image_loaded or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $image = lc($this->{event_data}{Image});
      my $image_loaded = lc($this->{event_data}{ImageLoaded});

      #push @{$ps{$image}{process_id}}, $process_id;
      push @{$ps{$image}{image_loaded}}, $image_loaded;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_driver_loaded {
   my $self = shift;

   my $r = $self->get_driver_loaded or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $hashes = $this->{event_data}{Hashes};
      my $image_loaded = lc($this->{event_data}{ImageLoaded});

      #push @{$ps{$image}{process_id}}, $process_id;
      push @{$ps{$image_loaded}{hashes}}, $hashes;
   }

   return $self->_dedup_values(\%ps);
   #my $deduped = $self->_dedup_values(\%ps);
   #for my $this (@$deduped) {
      #$this->{hashes} = $self->_read_hashes($this->{hashes}[0]);
   #}

   #return $deduped;
}

sub ps_parent_image {
   my $self = shift;

   my $r = $self->get_process_create or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $image = lc($this->{event_data}{Image});
      my $parent_image = $this->{event_data}{ParentImage};

      #push @{$ps{$image}{process_id}}, $process_id;
      push @{$ps{$image}{parent_image}}, $parent_image;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_target_filename_created {
   my $self = shift;

   my $r = $self->get_file_created or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $image = lc($this->{event_data}{Image});
      my $target_filename = $this->{event_data}{TargetFilename};

      #push @{$ps{$image}{process_id}}, $process_id;
      push @{$ps{$image}{target_filename}}, $target_filename;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_target_filename_changed {
   my $self = shift;

   my $r = $self->get_file_creation_time_changed or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $image = lc($this->{event_data}{Image});
      my $target_filename = $this->{event_data}{TargetFilename};

      #push @{$ps{$image}{process_id}}, $process_id;
      push @{$ps{$image}{target_filename}}, $target_filename;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_target_image {
   my $self = shift;

   my $r = $self->get_create_remote_thread or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{SourceProcessId};
      my $image = lc($this->{event_data}{SourceImage});
      my $target_image = $this->{event_data}{TargetImage};

      #push @{$ps{$image}{process_id}}, $process_id;
      push @{$ps{$image}{target_image}}, $target_image;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_network_connections {
   my $self = shift;

   my $r = $self->get_network_connection_detected or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $image = lc($this->{event_data}{Image});
      my $src_ip = $this->{event_data}{SourceIp};
      my $src_hostname = $this->{event_data}{SourceHostname} || '';
      my $dest_ip = $this->{event_data}{DestinationIp};
      my $dest_hostname = $this->{event_data}{DestinationHostname} || '';
      my $src_port = $this->{event_data}{SourcePort};
      my $dest_port = $this->{event_data}{DestinationPort};
      my $protocol = $this->{event_data}{Protocol};
      my $connection = {
         src_ip => $src_ip,
         src_hostname => $src_hostname,
         dest_ip => $dest_ip,
         dest_hostname => $dest_hostname,
         src_port => $src_port,
         dest_port => $dest_port,
         protocol => $protocol,
      };
      #push @{$ps{$process_id}{$image}}, $connection;
      push @{$ps{$image}{connections}}, $connection;
   }

   return \%ps;
}

sub ps_registry_object_added_or_deleted {
   my $self = shift;

   my $r = $self->get_registry_object_added_or_deleted or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $image = lc($this->{event_data}{Image});
      my $target_object = $this->{event_data}{TargetObject};

      push @{$ps{$image}{target_object}}, $target_object;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_registry_value_set {
   my $self = shift;

   my $r = $self->get_registry_value_set or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{ProcessId};
      my $image = lc($this->{event_data}{Image});
      my $target_object = $this->{event_data}{TargetObject};

      push @{$ps{$image}{target_object}}, $target_object;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_target_process_accessed {
   my $self = shift;

   my $r = $self->get_process_accessed or return;

   my %ps = ();
   for my $this (@$r) {
      #my $process_id = $this->{event_data}{SourceProcessId};
      my $image = lc($this->{event_data}{SourceImage});
      my $target_image = $this->{event_data}{TargetImage};

      push @{$ps{$image}{target_image}}, $target_image;
   }

   return $self->_dedup_values(\%ps);
}

sub list_users {
   my $self = shift;

   my $r = $self->unique_values('event_data.User') or return;

   my %h = ();
   if (exists($r->{aggregations})
   &&  exists($r->{aggregations}{1})
   &&  exists($r->{aggregations}{1}{buckets})) {
      my $buckets = $r->{aggregations}{1}{buckets};
      for (@$buckets) {
         $h{$_->{key}}++;
      }
   }

   return [ sort { $a cmp $b} keys %h ];
}

sub list_sessions {
   my $self = shift;

   my $r = $self->unique_values('event_data.LogonGuid') or return;

   my %h = ();
   if (exists($r->{aggregations})
   &&  exists($r->{aggregations}{1})
   &&  exists($r->{aggregations}{1}{buckets})) {
      my $buckets = $r->{aggregations}{1}{buckets};
      for (@$buckets) {
         $h{$_->{key}}++;
      }
   }

   return [ sort { $a cmp $b} keys %h ];
}

sub list_computer_names {
   my $self = shift;

   my $r = $self->unique_values('computer_name') or return;

   my %h = ();
   if (exists($r->{aggregations})
   &&  exists($r->{aggregations}{1})
   &&  exists($r->{aggregations}{1}{buckets})) {
      my $buckets = $r->{aggregations}{1}{buckets};
      for (@$buckets) {
         $h{$_->{key}}++;
      }
   }

   return [ sort { $a cmp $b} keys %h ];
}

sub list_domains {
   my $self = shift;

   my $r = $self->unique_values('user.domain') or return;

   my %h = ();
   if (exists($r->{aggregations})
   &&  exists($r->{aggregations}{1})
   &&  exists($r->{aggregations}{1}{buckets})) {
      my $buckets = $r->{aggregations}{1}{buckets};
      for (@$buckets) {
         $h{$_->{key}}++;
      }
   }

   return [ sort { $a cmp $b} keys %h ];
}

1;

__END__

=head1 NAME

Metabrik::Forensic::Sysmon - forensic::sysmon Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
