#
# $Id: Os.pm 89 2014-09-17 20:29:29Z gomor $
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

sub revision {
   return '$Revision$';
}

sub require_modules {
   return {
      'POSIX' => [],
   };
}

sub help {
   return {
      'run:name' => '',
      'run:release' => '',
      'run:version' => '',
      'run:hostname' => '',
      'run:arch' => '',
   };
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
