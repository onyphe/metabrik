#
# $Id$
#
package Plashy::Log::Console;
use strict;
use warnings;

use base qw(Plashy::Log);
__PACKAGE__->cgBuildIndices;

1;

__END__

=head1 NAME

Plashy::Log::Console - logging directly on the console

=head1 SYNOPSIS

   use Plashy::Log::Console;

   my $log = Plashy::Log::Console->new(
      level => 1,
   );

=head1 DESCRIPTION

=head1 METHODS

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
