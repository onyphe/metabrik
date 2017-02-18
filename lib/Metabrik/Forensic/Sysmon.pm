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
         from => [ qw(number) ],     # Inherited
         size => [ qw(count) ],      # Inherited
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
         ps_image_loaded => [ ],
         ps_parent_image => [ ],
         ps_target_filename_created => [ ],
         ps_target_filename_changed => [ ],
         ps_target_image => [ ],
         ps_network_connections => [ ],
         ps_registry_object_added_or_deleted => [ ],
         ps_registry_value_set => [ ],
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

   my $q = {
      size => 100,
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

sub _dedup_values {
   my $self = shift;
   my ($h) = @_;

   for my $this (keys %$h) {
      my $this_h = $h->{$this};
      for my $k (keys %$this_h) {
         my $ary = $this_h->{$k};
         my %uniq = map { $_ => 1 } @$ary;
         $this_h->{$k} = [ sort { $a cmp $b } keys %uniq ];
      }
   }

   return $h;
}

sub ps_image_loaded {
   my $self = shift;

   my $r = $self->get_image_loaded or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
      my $image_loaded = $this->{event_data}{ImageLoaded};
      push @{$ps{$process_id}{$image}}, $image_loaded;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_parent_image {
   my $self = shift;

   my $r = $self->get_process_create or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
      my $parent_image = $this->{event_data}{ParentImage};
      push @{$ps{$process_id}{$image}}, $parent_image;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_target_filename_created {
   my $self = shift;

   my $r = $self->get_file_created or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
      my $target_filename = $this->{event_data}{TargetFilename};
      push @{$ps{$process_id}{$image}}, $target_filename;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_target_filename_changed {
   my $self = shift;

   my $r = $self->get_file_creation_time_changed or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
      my $target_filename = $this->{event_data}{TargetFilename};
      push @{$ps{$process_id}{$image}}, $target_filename;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_target_image {
   my $self = shift;

   my $r = $self->get_create_remote_thread or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{SourceProcessId};
      my $image = $this->{event_data}{SourceImage};
      my $target_image = $this->{event_data}{TargetImage};
      push @{$ps{$process_id}{$image}}, $target_image;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_network_connections {
   my $self = shift;

   my $r = $self->get_network_connection_detected or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
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
      push @{$ps{$process_id}{$image}}, $connection;
   }

   return \%ps;
}

sub ps_registry_object_added_or_deleted {
   my $self = shift;

   my $r = $self->get_registry_object_added_or_deleted or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
      my $target_object = $this->{event_data}{TargetObject};
      push @{$ps{$process_id}{$image}}, $target_object;
   }

   return $self->_dedup_values(\%ps);
}

sub ps_registry_value_set {
   my $self = shift;

   my $r = $self->get_registry_value_set or return;

   my %ps = ();
   for my $this (@$r) {
      my $process_id = $this->{event_data}{ProcessId};
      my $image = $this->{event_data}{Image};
      my $target_object = $this->{event_data}{TargetObject};
      push @{$ps{$process_id}{$image}}, $target_object;
   }

   return $self->_dedup_values(\%ps);
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
