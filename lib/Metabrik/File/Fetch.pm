#
# $Id$
#
# file::fetch Brik
#
package Metabrik::File::Fetch;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable fetch wget) ],
      attributes => {
         output => [ qw(file) ],
      },
      commands => {
         get => [ qw(uri) ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'wget' => [ ],
      },
   };
}

sub get {
   my $self = shift;
   my ($uri) = @_;

   my $output = $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $cmd = "wget --output-document=$output $uri";

   return $self->context->run('shell::command', 'system', $cmd);
}

1;

__END__

=head1 NAME

Metabrik::File::Fetch - file::fetch Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
