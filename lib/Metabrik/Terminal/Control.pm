#
# $Id$
#
# terminal::control Brik
#
package Metabrik::Terminal::Control;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable terminal) ],
      commands => {
         title => [ qw(string) ],
      },
   };
}

sub title {
   my $self = shift;
   my ($title) = @_;

   if (! defined($title)) {
      return $self->log->error($self->brik_help_run('title'));
   }

   print "\c[];$title\a\e[0m";

   return $title;
}

1;

__END__

=head1 NAME

Metabrik::Terminal::Control - terminal::control Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
