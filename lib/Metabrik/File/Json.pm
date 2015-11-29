#
# $Id$
#
# file::json Brik
#
package Metabrik::File::Json;
use strict;
use warnings;

use base qw(Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         overwrite => 1,
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         write => [ qw($json_hash output_file|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Write' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         encoding => $self->global->encoding || 'utf8',
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg("read", $input) or return;

   my $data = $self->SUPER::read($input) or return;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $json = $sj->decode($data) or return;

   return $json;
}

sub write {
   my $self = shift;
   my ($json_hash, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg("write", $json_hash) or return;
   $self->brik_help_run_undef_arg("write", $output) or return;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $data = $sj->encode($json_hash) or return;

   $self->SUPER::write($data, $output) or return;

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Json - file::json Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
