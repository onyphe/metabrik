#
# $Id$
#
# system::kali::package Brik
#
package Metabrik::System::Kali::Package;
use strict;
use warnings;

use base qw(Metabrik::System::Ubuntu::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         ignore_error => 0,
      },
      commands => {
         search => [ qw(string) ],
         install => [ qw(package|$package_list) ],
         remove => [ qw(package|$package_list) ],
         update => [ ],
         upgrade => [ ],
         list => [ ],
         is_installed => [ qw(package|$package_list) ],
         which => [ qw(file) ],
         system_update => [ ],
         system_upgrade => [ ],
      },
      optional_binaries => {
         aptitude => [ ],
      },
      require_binaries => {
         'apt-get' => [ ],
         dpkg => [ ],
      },
      need_packages => {
         kali => [ qw(aptitude) ],
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::System::Kali::Package - system::kali::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
