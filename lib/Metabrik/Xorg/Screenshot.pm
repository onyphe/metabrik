#
# $Id$
#
# xorg::screenshot Brik
#
package Metabrik::Xorg::Screenshot;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable screenshot) ],
      attributes => {
         output => [ qw(file) ],
      },
      attributes_default => {
         output => 'screenshot.png',
      },
      commands => {
         active_window => [ ],
         full_screen => [ ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'scrot' => [ ],
      },
   };
}

sub active_window {
   my $self = shift;

   my $output = $self->output;
   my $context = $self->context;

   $self->log->verbose("Saving to file [$output]");

   my $cmd = "scrot --focused --border $output";
   return $context->run('shell::command', 'system', $cmd);
}

sub full_screen {
   my $self = shift;

   my $output = $self->output;
   my $context = $self->context;

   $self->log->verbose("Saving to file [$output]");

   my $cmd = "scrot $output";
   return $context->run('shell::command', 'system', $cmd);
}

1;

__END__

=head1 NAME

Metabrik::Xorg::Screenshot - xorg::screenshot Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
