#
# $Id$
#
# file::psv Brik
#
package Metabrik::File::Psv;
use strict;
use warnings;

use base qw(Metabrik::File::Csv);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         separator => "|",
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::File::Psv - file::psv Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
