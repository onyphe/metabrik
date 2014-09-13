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
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use POSIX;

sub help {
   print "run system::os name\n";
   print "run system::os release\n";
   print "run system::os version\n";
   print "run system::os hostname\n";
   print "run system::os arch\n";
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

   print $self->_uname->{name}."\n";

   return $self->_uname->{name};
}

sub release {
   my $self = shift;

   print $self->_uname->{release}."\n";

   return $self->_uname->{release};
}

sub version {
   my $self = shift;

   print $self->_uname->{version}."\n";

   return $self->_uname->{version};
}

sub hostname {
   my $self = shift;

   print $self->_uname->{hostname}."\n";

   return $self->_uname->{hostname};
}

sub arch {
   my $self = shift;

   print $self->_uname->{arch}."\n";

   return $self->_uname->{arch};
}

1;

__END__
