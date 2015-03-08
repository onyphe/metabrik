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
      tags => [ qw(unstable network sinfp3 sinfp osfp fingerprint fingerprinting) ],
      attributes => {
         datadir => [ qw(datadir) ],
         db => [ qw(sinfp3_db) ],
         target => [ qw(target_host) ],
         port => [ qw(tcp_port) ],
      },
      attributes_default => {
         target => 'www.example.com',
         port => 80,
         db => 'sinfp3.db',
      },
      commands => {
         active => [ qw(target|OPTIONAL tcp_port|OPTIONAL) ],
         export_active_db => [ qw(sinfp3_db|OPTIONAL) ],
      },
      require_modules => {
         'Net::SinFP3' => [ ],
         'Net::SinFP3::Log::Console' => [ ],
         'Net::SinFP3::Global' => [ ],
         'Net::SinFP3::Input::IpPort' => [ ],
         'Net::SinFP3::DB::SinFP3' => [ ],
         'Net::SinFP3::Mode::Active' => [ ],
         'Net::SinFP3::Search::Active' => [ ],
         'Net::SinFP3::Output::Console' => [ ],
      },
   };
}

sub active {
   my $self = shift;
   my ($target, $port) = @_;

   if ($< != 0) {
      return $self->log->error("active: must be root to run");
   }

   $target ||= $self->target;
   $port ||= $self->port;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   if (! -f $file) {
      return $self->log->error("active: SinFP3 db file [$file] not found");
   }

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      target => $target,
      port => $port,
      ipv6 => 0,
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

sub export_active_db {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->db;
   if (! -f $file) {
      return $self->log->error("export_active_db: file [$file] not found");
   }

}

1;

__END__

=head1 NAME

Metabrik::Network::Sinfp3 - network::sinfp3 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
