#
# $Id$
#
# worker::fork Brik
#
package Metabrik::Worker::Fork;
use strict;
use warnings;

use base qw(Metabrik);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable worker fork process) ],
      attributes => {
         pid => [ qw(forked_process_id) ],
      },
      commands => {
         start => [ ],
         stop => [ ],
      },
      require_modules => {
         'POSIX' => [ ],
      },
   };
}

sub start {
   my $self = shift;

   # Fork a new process
   defined(my $pid = fork()) or return $self->log->error("start: fork: $!");
   if ($pid) { # Father
      my $restore = $SIG{INT};

      $SIG{CHLD} = "IGNORE";

      $SIG{INT} = sub {
         $self->debug && $self->log->debug("SIGINT: caught, son QUITs now");
         kill('QUIT', $pid);
         $SIG{INT} = $restore;
         return 1;
      };
   }

   # Return to father and son processes
   return $self->pid($pid);
}

sub stop {
   my $self = shift;

   if ($self->pid) {
      kill('QUIT', $self->pid);
      # Not needed now, we just ignore SIGCHLD
      #waitpid($self->_pid, POSIX::WNOHANG());  # Cleanup zombie state
      $self->pid(undef);
   }

   return 1;
}

sub brik_fini {
   my $self = shift;

   return $self->stop;
}

1;

__END__

=head1 NAME

Metabrik::Worker::Fork - worker::fork Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
