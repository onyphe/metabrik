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
      tags => [ qw(unstable perl module install cpan) ],
      commands => {
         install => [ qw(module|$module_list) ],
      },
      attributes_default => {
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

   if (ref($module) eq 'ARRAY') {
      for my $this (@$module) {
         if ($this !~ /^[A-Za-z0-9:_]+$/) {
            $self->log->error("install: invalid format for module [$module]");
            next;
         }

         $self->system("cpanm $this");
      }

      return 1;
   }
   elsif (! ref($module)) {
      if ($module !~ /^[A-Za-z0-9:_]+$/) {
         return $self->log->error("install: invalid format for module [$module]");
      }

      return $self->system("cpanm $module");
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
