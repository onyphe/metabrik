#
# $Id$
#
# system::service Brik
#
package Metabrik::System::Service;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable system service daemon) ],
      commands => {
         status => [ qw(service_name) ],
         start => [ qw(service_name) ],
         stop => [ qw(service_name) ],
         restart => [ qw(service_name) ],
      },
      require_binaries => {
         'service', => [ ],
      },
   };
}

sub status {
   my $self = shift;
   my ($name) = @_;

   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('status'));
   }

   return $self->system("service $name status");
}

sub start {
   my $self = shift;
   my ($name) = @_;

   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('start'));
   }

   return $self->system("sudo service $name start");
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('stop'));
   }

   return $self->system("sudo service $name stop");
}

sub restart {
   my $self = shift;
   my ($name) = @_;

   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('restart'));
   }

   $self->stop($name) or return;

   sleep(1);

   return $self->start($name);
}

1;

__END__

=head1 NAME

Metabrik::System::Service - system::service Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
