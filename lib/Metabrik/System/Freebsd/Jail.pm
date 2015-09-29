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
      },
      require_binaries => {
         'sudo' => [ ],
         'ezjail-admin' => [ ],
      },
   };
}

sub list {
   my $self = shift;

   my $cmd = "ezjail-admin list";

   return $self->capture($cmd);
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
