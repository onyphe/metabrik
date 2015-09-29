#
# $Id$
#
# network::rsync Brik
#
package Metabrik::Network::Rsync;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network rsync) ],
      commands => {
         sync => [ qw(source destination) ],
      },
      attributes => {
         use_ssh => [ qw(0|1) ],
         ssh_port => [ qw(port) ],
         ssh_args => [ qw(args) ],
         args => [ qw(args) ],
         sudo_mode => [ qw(0|1) ],
      },
      require_binaries => {
         'rsync', => [ ],
         'sudo', => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         use_ssh => 1,
         ssh_port => 22,
         args => '-azv',
         sudo_mode => 0,
      },
   };
}

sub sync {
   my $self = shift;
   my ($source, $destination) = @_;

   if (! defined($source)) {
      return $self->log->error($self->brik_help_run('sync'));
   }
   if (! defined($destination)) {
      return $self->log->error($self->brik_help_run('destination'));
   }

   my $cmd = "rsync";
   if ($self->use_ssh) {
      my $port = $self->ssh_port;
      my $args = $self->args;
      my $ssh_args = '';
      if ($self->ssh_args) {
         $ssh_args = $self->ssh_args;
      }
      $cmd .= " -e \"ssh -p $port $ssh_args\" $args $source $destination";
   }
   else {
      my $args = $self->args;
      $cmd .= " $args $source $destination";
   }

   if ($self->sudo_mode) {
      # Preserve environment like SSH_AGENT_PID
      $cmd = "sudo -E $cmd";
   }

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Network::Rsync - network::rsync Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
