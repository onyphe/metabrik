#
# $Id$
#
# perl::module Brik
#
package Metabrik::Perl::Module;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable perl module install cpan) ],
      commands => {
         install => [ qw(Module) ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'metabrik-cpanm' => [ ],
      },
   };
}

sub install {
   my $self = shift;
   my ($module) = @_;

   if (! defined($module)) {
      return $self->log->error($self->brik_help_run('install'));
   }

   if ($module !~ /^[A-Za-z0-9:]+$/) {
      return $self->log->error("install: module [$module]: invalid format");
   }

   my $context = $self->context;

   return $context->run('shell::command', 'system', "metabrik-cpanm $module");
}

1;

__END__

=head1 NAME

Metabrik::Perl::Module - perl::module Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
