#
# $Id$
#
# network::sinfp3 Brik
#
package Metabrik::Network::Sinfp3;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable sinfp osfp fingerprint fingerprinting) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         db => [ qw(sinfp3_db) ],
         target => [ qw(target_host) ],
         port => [ qw(tcp_port) ],
         device => [ qw(device) ],
      },
      attributes_default => {
         port => 80,
         db => 'sinfp3.db',
      },
      commands => {
         update => [ ],
         active_ipv4 => [ qw(target|OPTIONAL tcp_port|OPTIONAL) ],
         active_ipv6 => [ qw(target|OPTIONAL tcp_port|OPTIONAL) ],
         export_active_db => [ qw(sinfp3_db|OPTIONAL) ],
         save_active_ipv4_fingerprint => [ qw(target_host|OPTIONAL target_port|OPTIONAL) ],
         save_active_ipv6_fingerprint => [ qw(target_host|OPTIONAL target_port|OPTIONAL) ],
         active_ipv4_from_pcap => [ qw(pcap_file) ],
         active_ipv6_from_pcap => [ qw(pcap_file) ],
      },
      require_modules => {
         'File::Copy' => [ qw(move) ],
         'Net::SinFP3' => [ ],
         'Net::SinFP3::Log::Console' => [ ],
         'Net::SinFP3::Global' => [ ],
         'Net::SinFP3::Input::IpPort' => [ ],
         'Net::SinFP3::Input::Pcap' => [ ],
         'Net::SinFP3::DB::SinFP3' => [ ],
         'Net::SinFP3::Mode::Active' => [ ],
         'Net::SinFP3::Search::Active' => [ ],
         'Net::SinFP3::Search::Null' => [ ],
         'Net::SinFP3::Output::Console' => [ ],
         'Net::SinFP3::Output::Pcap' => [ ],
         'Net::SinFP3::Output::Simple' => [ ],
         'Metabrik::Client::Www' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device,
      },
   };
}

sub update {
   my $self = shift;

   my $db = $self->db;
   my $datadir = $self->datadir;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $files = $cw->mirror("http://www.metabrik.org/wp-content/files/sinfp/sinfp3-latest.db", $db, $datadir) or return;
   if (@$files > 0) {
      $self->log->info("update: $db updated");
   }

   return "$datadir/$db";
}

sub active_ipv4 {
   my $self = shift;
   my ($target, $port) = @_;

   $self->brik_help_run_must_be_root('active_ipv4') or return;

   $target ||= $self->target;
   $port ||= $self->port;
   my $device = $self->device;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('active_ipv4', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      target => $target,
      port => $port,
      ipv6 => 0,
      dnsReverse => 0,
      worker => 'single',
      device => $device,
   ) or return $self->log->error("active: global failed");

   my $input = Net::SinFP3::Input::IpPort->new(
      global => $global,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Simple->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   my @result = $global->result;

   $db->post;
   $log->post;

   return \@result;

   # I was quite mad at this time.
   #$global->mode($mode);
   #$mode->init;
   #$mode->run;
   #$db->init;
   #$db->run;
   #$global->db($db);
   #$global->search($search);
   #$search->init;
   #my $result = $search->run;

   #return $result;
}

sub export_active_db {
   my $self = shift;
   my ($db) = @_;

   $db ||= $self->db;
   $self->brik_help_run_undef_arg('export_active_db', $db) or return;
   $self->brik_help_run_file_not_found('export_active_db', $db) or return;

   return 1;
}

sub save_active_ipv4_fingerprint {
   my $self = shift;
   my ($target_host, $target_port) = @_;

   $target_host ||= $self->target;
   $target_port ||= $self->port;
   my $device = $self->device;
   $self->brik_help_run_undef_arg('save_active_ipv4_fingerprint', $target_host) or return;
   $self->brik_help_run_undef_arg('save_active_ipv4_fingerprint', $target_port) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('save_active_ipv4_fingerprint', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      target => $target_host,
      port => $target_port,
      ipv6 => 0,
      dnsReverse => 0,
      device => $device,
   ) or return $self->log->error("save_active_ipv4_fingerprint: global failed");

   my $input = Net::SinFP3::Input::IpPort->new(
      global => $global,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Pcap->new(
      global => $global,
      anonymize => 1,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   my $pcap = 'sinfp4-127.0.0.1-'.$target_port.'.pcap';
   if (-f $pcap) {
      File::Copy::move($pcap, $datadir);
   }

   return $datadir."/$pcap";
}

sub save_active_ipv6_fingerprint {
   my $self = shift;
   my ($target_host, $target_port) = @_;

   $target_host ||= $self->target;
   $target_port ||= $self->port;
   my $device = $self->device;
   $self->brik_help_run_undef_arg('save_active_ipv6_fingerprint', $target_host) or return;
   $self->brik_help_run_undef_arg('save_active_ipv6_fingerprint', $target_port) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('save_active_ipv6_fingerprint', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      target => $target_host,
      port => $target_port,
      ipv6 => 1,
      dnsReverse => 0,
      device => $device,
   ) or return $self->log->error("save_active_ipv6_fingerprint: global failed");

   my $input = Net::SinFP3::Input::IpPort->new(
      global => $global,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Pcap->new(
      global => $global,
      anonymize => 1,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   my $pcap = 'sinfp6-::1-'.$target_port.'.pcap';
   if (-f $pcap) {
      File::Copy::move($pcap, $datadir);
   }

   return $datadir."/$pcap";
}

sub active_ipv4_from_pcap {
   my $self = shift;
   my ($pcap_file) = @_;

   my $device = $self->device;
   $self->brik_help_run_undef_arg('active_ipv4_from_pcap', $pcap_file) or return;
   $self->brik_help_run_file_not_found('active_ipv4_from_pcap', $pcap_file) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('active_ipv4_from_pcap', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      ipv6 => 0,
      dnsReverse => 0,
      device => $device,
   ) or return $self->log->error("active_ipv4_from_pcap: global failed");

   my $input = Net::SinFP3::Input::Pcap->new(
      global => $global,
      file => $pcap_file,
      count => 10,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Console->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   return $ret;
}

sub active_ipv6_from_pcap {
   my $self = shift;
   my ($pcap_file) = @_;

   my $device = $self->device;
   $self->brik_help_run_undef_arg('active_ipv6_from_pcap', $pcap_file) or return;
   $self->brik_help_run_file_not_found('active_ipv6_from_pcap', $pcap_file) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('active_ipv6_from_pcap', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      ipv6 => 1,
      dnsReverse => 0,
      device => $device,
   ) or return $self->log->error("active_ipv6_from_pcap: global failed");

   my $input = Net::SinFP3::Input::Pcap->new(
      global => $global,
      file => $pcap_file,
      count => 10,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Console->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   return $ret;
}

1;

__END__

=head1 NAME

Metabrik::Network::Sinfp3 - network::sinfp3 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
