#
# $Id$
#
# system::package Brik
#
package Metabrik::System::Package;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable system package) ],
      attributes => {
         _sp => [ qw(INTERNAL) ],
      },
      commands => {
         search => [ qw(string) ],
         install => [ qw(package) ],
         update => [ ],
         upgrade => [ ],
      },
      require_modules => {
         'Metabrik::System::Os' => [ ],
         'Metabrik::System::Ubuntu::Package' => [ ],
         'Metabrik::System::Freebsd::Package' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $so = Metabrik::System::Os->new_from_brik_init($self) or return;

   my $distrib = $so->distribution
      or return $self->log->error("brik_init: distribution failed");

   my $sp;
   my $name = $distrib->{name};
   if ($name eq 'Ubuntu') {
      $sp = Metabrik::System::Ubuntu::Package->new_from_brik_init($self) or return;
   }
   elsif ($name eq 'FreeBSD') {
      $sp = Metabrik::System::Freebsd::Package->new_from_brik_init($self) or return;
   }

   if (! defined($sp)) {
      return $self->log->error("brik_init: cannot determine system distribution");
   }

   $self->_sp($sp);

   return $self->SUPER::brik_init(@_);
}

sub search {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('search'));
   }

   return $self->_sp->search($package);
}

sub install {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('install'));
   }

   return $self->_sp->install($package);
}

sub update {
   my $self = shift;

   return $self->_sp->update;
}

sub upgrade {
   my $self = shift;

   return $self->_sp->upgrade;
}

sub list {
   my $self = shift;

   return $self->_sp->list;
}

1;

__END__

=head1 NAME

Metabrik::System::Package - system::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
