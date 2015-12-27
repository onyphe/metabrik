#
# $Id$
#
# system::freebsd::package Brik
#
package Metabrik::System::Freebsd::Package;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         search => [ qw(string) ],
         install => [ qw(package) ],
         update => [ ],
         upgrade => [ ],
         list => [ ],
         is_installed => [ qw(package|$package_list) ],
         which => [ qw(file) ],
      },
      require_binaries => {
         'sudo' => [ ],
         'pkg' => [ ],
      },
   };
}

sub search {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('search', $package) or return;

   my $cmd = "pkg search $package";

   return $self->capture($cmd);
}

sub install {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('install', $package) or return;
   my $ref = $self->brik_help_run_invalid_arg('install', $package, 'ARRAY', 'SCALAR')
      or return;

   my $cmd = "sudo pkg install ";
   $ref eq 'ARRAY' ? ($cmd .= join(' ', @$package)) : ($cmd .= $package);

   return $self->system($cmd);
}

sub update {
   my $self = shift;

   my $cmd = "sudo pkg update";

   return $self->system($cmd);
}

sub upgrade {
   my $self = shift;

   my $cmd = "sudo pkg upgrade";

   return $self->system($cmd);
}

sub list {
   my $self = shift;

   my $cmd = "pkg info";

   return $self->system($cmd);
}

sub is_installed {
   my $self = shift;

   return $self->log->info("is_installed: not implemented on this system");
}

sub which {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('which', $file) or return;
   $self->brik_help_run_file_not_found('which', $file) or return;

   my $cmd = "pkg which $file";
   my $lines = $self->capture($cmd) or return;
   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);
      if (defined($toks[0]) && ($toks[0] eq $file) && defined($toks[5])) {
         return $toks[5];
      }
   }

   return 'undef';
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Package - system::freebsd::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
