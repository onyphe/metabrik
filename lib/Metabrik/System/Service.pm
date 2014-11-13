#
# $Id$
#
# system::service Brik
#
package Metabrik::System::Service;
use strict;
use warnings;

use base qw(Metabrik);

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
      require_used => {
         'shell::command' => [ ],
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

   return $self->context->run('shell::command', 'system', "service $name status");
}

sub start {
   my $self = shift;
   my ($name) = @_;

   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('start'));
   }

   return $self->context->run('shell::command', 'system', "sudo service $name start");
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('stop'));
   }

   return $self->context->run('shell::command', 'system', "sudo service $name stop");
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
