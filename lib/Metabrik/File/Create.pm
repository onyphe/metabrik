#
# $Id$
#
# file::create Brik
#
package Metabrik::File::Create;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable dd) ],
      attributes => {
         max_size => [ qw(integer) ],
      },
      attributes_default => {
         max_size => 10_000_000, # 10MB
      },
      commands => {
         fixed_size => [ qw(SCALAR) ],
      },
      require_binaries => {
         'dd' => [ ],
      },
   };
}

sub fixed_size {
   my $self = shift;
   my ($filename) = @_;

   if (! defined($filename)) {
      return $self->log->error($self->brik_help_run('fixed_size'));
   }

   my $cmd = "dd if=/dev/zero of=$filename bs=1 count=".$self->max_size;

   return $self->context->run('shell::command', 'system', $cmd);
}

1;

__END__
