#
# $Id$
#
# shell::command Brik
#
package Metabrik::Brik::Shell::Command;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell command system) ],
      commands => {
         system => [ ],
         capture => [ ],
      },
   };
}

sub system {
   my $self = shift;
   my ($cmd) = @_;

   if (! defined($cmd)) {
      return $self->log->info($self->brik_help_run('system'));
   }

   my $r = CORE::system($cmd);

   return defined($r) ? 1 : 0;
}

sub capture {
   my $self = shift;
   my ($cmd) = @_;

   if (! defined($cmd)) {
      return $self->log->info($self->brik_help_run('system'));
   }

   my $r = `$cmd`;

   return $r;
}

1;

__END__
