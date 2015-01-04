#
# $Id$
#
# system::os brik
#
package Metabrik::System::Os;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable os uname) ],
      attributes => {
         _uname => [ qw(INTERNAL) ],
      },
      commands => {
         name => [ ],
         release => [ ],
         version => [ ],
         hostname => [ ],
         arch => [ ],
      },
      require_modules => {
         'POSIX' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

   $self->_uname({
      name => $sysname,
      hostname => $nodename,
      release => $release,
      version => $version,
      arch => $machine,
   });

   return $self->SUPER::brik_init;
}

sub name {
   my $self = shift;

   return $self->_uname->{name};
}

sub release {
   my $self = shift;

   return $self->_uname->{release};
}

sub version {
   my $self = shift;

   return $self->_uname->{version};
}

sub hostname {
   my $self = shift;

   return $self->_uname->{hostname};
}

sub arch {
   my $self = shift;

   return $self->_uname->{arch};
}

1;

__END__

=head1 NAME

Metabrik::System::os - system::os Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
