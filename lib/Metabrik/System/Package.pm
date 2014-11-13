#
# $Id: Package.pm 177 2014-10-02 18:02:40Z gomor $
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
      tags => [ qw(experimental package) ],
      commands => {
         search => [ qw(string) ],
         install => [ qw(package) ],
         update => [ ],
         upgrade => [ ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'aptitude' => [ ],
      },
   };
}

sub search {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('search'));
   }

   my $cmd = "aptitude search $package";

   return $self->context->run('shell::command', 'system', $cmd);
}

sub install {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('install'));
   }

   my $cmd = "sudo apt-get install $package";

   return $self->context->run('shell::command', 'system', $cmd);
}

sub update {
   my $self = shift;

   my $cmd = "sudo apt-get update";

   return $self->context->run('shell::command', 'system', $cmd);
}

sub upgrade {
   my $self = shift;

   my $cmd = "sudo apt-get upgrade";

   return $self->context->run('shell::command', 'system', $cmd);
}

1;

__END__
