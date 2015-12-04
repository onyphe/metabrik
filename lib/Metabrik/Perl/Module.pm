#
# $Id$
#
# perl::module Brik
#
package Metabrik::Perl::Module;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable core build test install cpan cpanm) ],
      commands => {
         build => [ qw(module|$module_list|OPTIONAL) ],
         test => [ qw(module|$module_list|OPTIONAL) ],
         install => [ qw(module|$module_list|OPTIONAL) ],
      },
      attributes => {
         use_test => [ qw(0|1) ],
         use_sudo => [ qw(0|1) ],
      },
      attributes_default => {
         use_test => 0,
         use_sudo => 1,
      },
      require_binaries => {
         'cpanm' => [ ],
      },
   };
}

sub build {
   my $self = shift;
   my ($module) = @_;

   my @cmd = ();
   if (-f 'Build.PL') {
      @cmd = ( 'perl Build.PL', 'perl Build' );
   }
   elsif (-f 'Makfile.PL') {
      @cmd = ( 'perl Makefile.PL', 'make' );
   }
   else {
      return $self->log->error("build: neither Build.PL nor Makefile.PL were found, abort");
   }

   my $r;
   $self->use_sudo(0);
   for (@cmd) {
      $r = $self->execute($_) or last; # Abord if one cmd failed
   }
   $self->use_sudo(1);

   return $r;
}

sub test {
   my $self = shift;
   my ($module) = @_;

   my $cmd;
   if (-f 'Build.PL') {
      $cmd = 'perl Build test';
   }
   elsif (-f 'Makfile.PL') {
      $cmd = 'make test';
   }
   else {
      return $self->log->error("build: neither Build nor Makefile were found, abort");
   }

   $self->use_sudo(0);
   my $r = $self->execute($cmd);
   $self->use_sudo(1);

   return $r;
}

sub install {
   my $self = shift;
   my ($module) = @_;

   my $cmd;
   if (defined($module)) {
      my $ref = $self->brik_help_run_invalid_arg('install', $module, 'ARRAY', 'SCALAR')
         or return;

      $cmd = $self->use_test ? 'cpanm' : 'cpanm -n';
      if ($ref eq 'ARRAY') {
         $cmd = join(' ', $cmd, @$module);
      }
      else {
         $cmd = join(' ', $cmd, $module);
      }
   }
   else {
      if (-f 'Build') {
         $cmd = 'perl Build install';
      }
      elsif (-f 'Makefile') {
         $cmd = 'make install';
      }
      else {
         return $self->log->error("install: neither Build nor Makefile were found, abort");
      }
   }

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Perl::Module - perl::module Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
