#
# $Id$
#
# file::base64 Brik
#
package Metabrik::File::Base64;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         decode => [ qw(input output) ],
         encode => [ qw(input output) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::String::Base64' => [ ],
      },
   };
}

sub decode {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('decode', $input) or return;
   $self->brik_help_run_file_not_found('decode', $input) or return;
   $self->brik_help_run_undef_arg('decode', $output) or return;

   my $ft_in = Metabrik::File::Text->new_from_brik_init($self) or return;
   my $string = $ft_in->read($input) or return;

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   my $decoded = $sb->decode($string) or return;

   my $ft_out = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft_out->overwrite(1);
   $ft_out->append(0);
   $ft_out->write($decoded, $output) or return;

   return $output;
}

sub encode {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('encode', $input) or return;
   $self->brik_help_run_file_not_found('encode', $input) or return;
   $self->brik_help_run_undef_arg('encode', $output) or return;

   my $ft_in = Metabrik::File::Text->new_from_brik_init($self) or return;
   my $string = $ft_in->read($input) or return;

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   my $encoded = $sb->encode($string) or return;

   my $ft_out = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft_out->overwrite(1);
   $ft_out->append(0);
   $ft_out->write($encoded, $output) or return;

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Base64 - file::base64 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
