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
         build => [ qw(directory|OPTIONAL) ],
         test => [ qw(directory|OPTIONAL) ],
         install => [ qw(module|$module_list|directory|OPTIONAL) ],
         dist => [ qw(directory|OPTIONAL) ],
      },
      attributes => {
         use_test => [ qw(0|1) ],
         use_sudo => [ qw(0|1) ],
      },
      attributes_default => {
         use_test => 0,
         use_sudo => 1,
      },
      require_modules => {
         'Cwd' => [ qw(chdir cwd) ],
      },
      require_binaries => {
         'cpanm' => [ ],
      },
   };
}

sub build {
   my $self = shift;
   my ($directory) = @_;

   $directory ||= '';
   my $cwd = Cwd::cwd();
   if (length($directory)) {
      $self->brik_help_run_directory_not_found('build', $directory) or return;
      Cwd::chdir($directory);
   }

   my @cmd = ();
   if (-f 'Build.PL') {
      @cmd = ( 'perl Build.PL', 'perl Build' );
   }
   elsif (-f 'Makefile.PL') {
      @cmd = ( 'perl Makefile.PL', 'make' );
   }
   else {
      Cwd::chdir($cwd);
      return $self->log->error("build: neither Build.PL nor Makefile.PL were found, abort");
   }

   my $r;
   $self->use_sudo(0);
   for (@cmd) {
      $r = $self->execute($_) or last; # Abord if one cmd failed
   }
   $self->use_sudo(1);

   Cwd::chdir($cwd);

   return $r;
}

sub test {
   my $self = shift;
   my ($directory) = @_;

   $directory ||= '';
   my $cwd = Cwd::cwd();
   if (length($directory)) {
      $self->brik_help_run_directory_not_found('test', $directory) or return;
      Cwd::chdir($directory);
   }

   my $cmd;
   if (-f 'Build') {
      $cmd = 'perl Build test';
   }
   elsif (-f 'Makefile') {
      $cmd = 'make test';
   }
   else {
      Cwd::chdir($cwd);
      return $self->log->error("build: neither Build nor Makefile were found, abort");
   }

   $self->use_sudo(0);
   my $r = $self->execute($cmd);
   $self->use_sudo(1);

   Cwd::chdir($cwd);

   return $r;
}

sub install {
   my $self = shift;
   my ($module) = @_;

   my $cmd;
   my $cwd = Cwd::cwd();
   if ((defined($module) && -d $module) || (! defined($module))) {
      my $directory = $module || ''; # We consider there is only one arg: the directory where 
                                     # to find the module to install
      if (length($directory)) {
         $self->brik_help_run_directory_not_found('install', $directory) or return;
         Cwd::chdir($directory);
      }

      if (-f 'Build') {
         $cmd = 'perl Build install';
      }
      elsif (-f 'Makefile') {
         $cmd = 'make install';
      }
      else {
         Cwd::chdir($cwd);
         return $self->log->error("install: neither Build nor Makefile were found, abort");
      }
   }
   else {
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

   my $r = $self->execute($cmd);

   Cwd::chdir($cwd);

   return $r;
}

sub dist {
   my $self = shift;
   my ($directory) = @_;

   $directory ||= '';
   my $cwd = Cwd::cwd();
   if (length($directory)) {
      $self->brik_help_run_directory_not_found('dist', $directory) or return;
      Cwd::chdir($directory);
   }

   my $cmd;
   if (-f 'Build') {
      $cmd = 'perl Build dist';
   }
   elsif (-f 'Makefile') {
      $cmd = 'make dist';
   }
   else {
      Cwd::chdir($cwd);
      return $self->log->error("build: neither Build nor Makefile were found, abort");
   }

   $self->use_sudo(0);
   my $r = $self->execute($cmd);
   $self->use_sudo(1);

   Cwd::chdir($cwd);

   return $r;
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
