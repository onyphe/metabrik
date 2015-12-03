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
      tags => [ qw(unstable core install cpan cpanm) ],
      commands => {
         install => [ qw(module|$module_list) ],
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

sub install {
   my $self = shift;
   my ($module) = @_;

   if (! defined($module)) {
      return $self->log->error($self->brik_help_run('install'));
   }
   my $ref = ref($module);
   if ($ref ne '' && $ref ne 'ARRAY') {
      return $self->log->error("install: module [$module] has invalid format");
   }

   my $cmd = $self->use_test ? "cpanm" : "cpanm -n";

   if ($ref eq 'ARRAY') {
      $self->system(join(' ', $cmd, @$module));
   }
   elsif ($ref eq '') {
      $self->system(join(' ', $cmd, $module));
   }

   return 1;
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
