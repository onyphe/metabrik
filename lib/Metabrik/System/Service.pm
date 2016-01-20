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
      tags => [ qw(unstable daemon) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         status => [ qw(service_name) ],
         start => [ qw(service_name) ],
         stop => [ qw(service_name) ],
         restart => [ qw(service_name) ],
         my_os => [ ],
      },
      require_modules => {
         'Metabrik::System::Os' => [ ],
      },
      require_binaries => {
         'service', => [ ],
      },
   };
}

sub status {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      return $self->execute("service $name status");
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('status'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->execute("service $service status");
         }
      }
      else {
         return $self->log->error("status: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub start {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      return $self->execute("sudo service $name start");
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('start'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->execute("sudo service $service start");
         }
      }
      else {
         return $self->log->error("start: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      return $self->execute("sudo service $name stop");
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('stop'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->execute("sudo service $service stop");
         }
      }
      else {
         return $self->log->error("stop: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub restart {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      $self->stop($name) or return;
      sleep(1);
      return $self->start($name);
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('restart'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->stop($name) or next;
            sleep(1);
            $self->start($name);
         }
      }
      else {
         return $self->log->error("restart: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub remove {
# XXX: ubuntu: update-rc.d <service> remove
}

sub my_os {
   my $self = shift;

   my $so = Metabrik::System::Os->new_from_brik_init($self) or return;
   return $so->my;
}

1;

__END__

=head1 NAME

Metabrik::System::Service - system::service Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
