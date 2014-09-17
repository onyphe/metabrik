#
# $Id$
#
# system::os brick
#
package Metabricky::Brick::System::Os;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   _uname
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub require_modules {
   return [
      'POSIX',
   ];
}

sub help {
   return [
      'run system::os name',
      'run system::os release',
      'run system::os version',
      'run system::os hostname',
      'run system::os arch',
   ];
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

   $self->_uname({
      name => $sysname,
      hostname => $nodename,
      release => $release,
      version => $version,
      arch => $machine,
   });

   return $self;
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
