#
# $Id$
#
# system::freebsd::jail Brik
#
package Metabrik::System::Freebsd::Jail;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable system jail freebsd) ],
      commands => {
         list => [ ],
         start => [ qw(jail_name|$jail_list) ],
         stop => [ qw(jail_name|$jail_list) ],
         restart => [ qw(jail_name|$jail_list) ],
         create => [ qw(jail_name ip_address) ],
         backup => [ qw(jail_name|$jail_list) ],
         restore => [ qw(jail_name ip_address archive_tar_gz) ],
         delete => [ qw(jail_name) ],
         update => [ ],
         name_to_id => [ qw(jail_name) ],
         exec => [ qw(jail_name command) ],
      },
      require_binaries => {
         'sudo' => [ ],
         'ezjail-admin' => [ ],
         'jls' => [ ],
         'jexec' => [ ],
      },
   };
}

sub name_to_id {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('name_to_id'));
   }

   my $out = $self->capture("ezjail-admin list") or return;
   # STA JID  IP              Hostname                       Root Directory
   # --- ---- --------------- ------------------------------ ------------------------
   # DR  13   192.168.X.Y     smtpout                        /usr/jails/smtpout
   for my $line (@$out) {
      #print "DEBUG line[$line]\n";
      my @t = split(/\s+/, $line);
      #print "DEBUG [@t]\n";
      if (defined($t[1]) && $t[1] =~ /^\d+$/ && defined($t[3]) && $t[3] =~ /^$jail_name$/) {
         return $t[1];
      }
   }

   return $self->log->error("name_to_id: jail name not found");
}

sub exec {
   my $self = shift;
   my ($jail_name, $exec) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('exec'));
   }
   if (! defined($exec)) {
      return $self->log->error($self->brik_help_run('exec'));
   }

   my $r;
   my @lines = ();
   if (ref($jail_name) eq 'ARRAY') {
      for my $jail (@$jail_name) {
         my $id = $self->name_to_id($jail) or next;
         my $cmd = "sudo jexec $id $exec";
         $r = $self->execute($cmd);
         if ($self->capture_mode) {
            push @lines, $r;
         }
      }
   }
   else {
      my $id = $self->name_to_id($jail_name) or return;
      my $cmd = "sudo jexec $id $exec";
      $r = $self->execute($cmd);
      if ($self->capture_mode) {
         push @lines, $r;
      }
   }

   if ($self->capture_mode) {
      return \@lines;
   }

   return $r;
}

sub list {
   my $self = shift;

   my $cmd = "ezjail-admin list";

   return $self->execute($cmd);
}

sub stop {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('stop'));
   }

   if (ref($jail_name) eq 'ARRAY') {
      for my $jail (@$jail_name) {
         my $cmd = "sudo ezjail-admin stop $jail";
         $self->system($cmd);
      }
      return 1;
   }

   my $cmd = "sudo ezjail-admin stop $jail_name";

   return $self->system($cmd);
}

sub start {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('start'));
   }

   if (ref($jail_name) eq 'ARRAY') {
      for my $jail (@$jail_name) {
         my $cmd = "sudo ezjail-admin start $jail";
         $self->system($cmd);
      }
      return 1;
   }

   my $cmd = "sudo ezjail-admin start $jail_name";

   return $self->system($cmd);
}

sub restart {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('restart'));
   }

   if (ref($jail_name) eq 'ARRAY') {
      for my $jail (@$jail_name) {
         my $cmd = "sudo ezjail-admin restart $jail";
         $self->system($cmd);
      }
      return 1;
   }

   my $cmd = "sudo ezjail-admin restart $jail_name";

   return $self->system($cmd);
}

sub create {
   my $self = shift;
   my ($jail_name, $ip_address) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('create'));
   }
   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('create'));
   }

   my $cmd = "sudo ezjail-admin create $jail_name $ip_address";

   return $self->system($cmd);
}

sub backup {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('backup'));
   }

   if (ref($jail_name) eq 'ARRAY') {
      for my $jail (@$jail_name) {
         my $cmd = "sudo ezjail-admin archive -f $jail";
         $self->system($cmd);
      }
      return 1;
   }

   my $cmd = "sudo ezjail-admin archive -f $jail_name";

   return $self->system($cmd);
}

sub restore {
   my $self = shift;
   my ($jail_name, $ip_address, $archive_tar_gz) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('restore'));
   }
   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('restore'));
   }
   if (! defined($archive_tar_gz)) {
      return $self->log->error($self->brik_help_run('restore'));
   }
      
   my $cmd = "sudo ezjail-admin create -a $archive_tar_gz $jail_name $ip_address";

   return $self->system($cmd);
}

sub delete {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('delete'));
   }

   if (ref($jail_name) eq 'ARRAY') {
      for my $jail (@$jail_name) {
         my $cmd = "sudo ezjail-admin delete -fw $jail";
         $self->system($cmd);
      }
      return 1;
   }

   my $cmd = "sudo ezjail-admin delete -fw $jail_name";

   return $self->system($cmd);
}

sub update {
   my $self = shift;

   my $cmd = "sudo ezjail-admin update -i";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Jail - system::freebsd::jail Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
