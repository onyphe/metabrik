#
# $Id$
#
# password::mirai Brik
#
package Metabrik::Password::Mirai;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable dictionary bruteforce iot) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         telnet => [ ],
      },
   };
}

#
# https://github.com/jgamblin/Mirai-Source-Code/blob/6a5941be681b839eeff8ece1de8b245bcd5ffb02/mirai/bot/scanner.c
#
sub telnet {
   my $self = shift;

   return [
      { login => '666666', pass => [ qw( 666666 ) ], },
      { login => '888888', pass => [ qw( 888888 ) ], },
      { login => 'admin', pass => [ "", qw( 1111 1111111 1234 12345 123456 54321 7ujMko0admin admin admin1234 meinsm pass password smcadmin ) ], },
      { login => 'admin1', pass => [ qw( password ) ], },
      { login => 'administrator', pass => [ qw( 1234 ) ], },
      { login => 'Administrator', pass => [ qw( admin ) ], },
      { login => 'guest', pass => [ qw( 12345 guest ) ], },
      { login => 'mother', passwords => [ qw( fucker ) ], },
      { login => 'root', passwords => [ "", qw( 00000000 1111 1234 12345 123456 54321 666666 7ujMko0admin 7ujMko0vizxv 888888 admin anko default dreambox hi3518 ikwb juantech jvbzd klv123 klv1234 pass password realtek root system user vizxv xc3511 xmhdipc zlxx.  Zte521 ) ], },
      { login => 'service', passwords => [ qw( service ) ], },
      { login => 'supervisor', passwords => [ qw( supervisor ) ], },
      { login => 'support', passwords => [ qw( support ) ], },
      { login => 'tech', passwords => [ qw( tech ) ], },
      { login => 'ubnt', passwords => [ qw( ubnt ) ], },
      { login => 'user', passwords => [ qw( user ) ], },
   ];
}

1;

__END__

=head1 NAME

Metabrik::Password::Mirai - password::mirai Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
