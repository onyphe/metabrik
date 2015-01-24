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
      tags => [ qw(unstable os uname linux freebsd distribution) ],
      attributes => {
         _uname => [ qw(INTERNAL) ],
      },
      commands => {
         name => [ ],
         release => [ ],
         version => [ ],
         hostname => [ ],
         arch => [ ],
         distribution => [ ],
      },
      require_modules => {
         'POSIX' => [ ],
         'Metabrik::File::Text' => [ ],
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

   return $self->SUPER::brik_init(@_);
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

   my $x86_64 = [ qw(x86 64) ];
   my $x86_32 = [ qw(x86 32) ];

   # Possible other values:
   # ia64, pc98, powerpc, powerpc64, sparc64

   my $arch = $self->_uname->{arch};
   if ($arch eq 'amd64' || $arch eq 'x86_64') {
      return $x86_64;
   }
   elsif ($arch eq 'i386' || $arch eq 'i685') {
      return $x86_32;
   }
   else {
      # We don't know, return raw result
      return [ $arch ];
   }

   # Error
   return;
}

sub distribution {
   my $self = shift;

   my $name = $self->name;
   my $release = $self->release;

   if ($name eq 'Linux') {
      my $ft = Metabrik::File::Text->new_from_brik($self) or return;
      $ft->as_array(1);

      # Ubuntu case
      if (-f '/etc/lsb-release') {
         my $lines = $ft->read('/etc/lsb-release')
            or return $self->log->error("distribution: read failed");

         my %info = ();
         for my $line (@$lines) {
            my ($k, $v) = split('\s*=\s*', $line);
            $info{$k} = $v;
         }

         return {
            name => $info{DISTRIB_ID},                 # Ubuntu
            release => $info{DISTRIB_RELEASE},         # 14.10
            codename => $info{DISTRIB_CODENAME},       # utopic
            description => $info{DISTRIB_DESCRIPTION}, # Ubuntu 14.10
         };
      }
   }

   # Default
   return {
      name => $name,
      release => $release,
      codename => $name,
      description => "$name $release",
   };
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
