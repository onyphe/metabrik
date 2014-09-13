#
# $Id$
#
package Metabricky::Brick::Log::Console;
use strict;
use warnings;

use base qw(Metabricky::Ext::Log Metabricky::Brick);
__PACKAGE__->cgBuildIndices;

1;

__END__

=head1 NAME

Metabricky::Brick::Log::Console - logging directly on the console

=head1 SYNOPSIS

   use Metabricky::Brick::Log::Console;

   my $log = Metabricky::Brick::Log::Console->new(
      level => 1,
   );

=head1 DESCRIPTION

=head1 COMMANDS

=over 4

=item B<new>

=item B<info>

=item B<warning>

=item B<error>

=item B<fatal>

=item B<verbose>

=item B<debug>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
