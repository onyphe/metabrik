#
# $Id$
#
# database::keystore Brik
#
package Metabrik::Database::Keystore;
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
         db => [ qw(db) ],
      },
      commands => {
         search => [ qw(pattern db|OPTIONAL) ],
         decrypt => [ qw(db|OPTIONAL) ],
         encrypt => [ qw($data) ],
         save => [ qw($data db|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Crypto::Aes' => [ ],
      },
   };
}

sub search {
   my $self = shift;
   my ($pattern, $db) = @_;

   $db ||= $self->db;
   $self->brik_help_run_undef_arg('search', $pattern) or return;
   $self->brik_help_run_undef_arg('search', $db) or return;

   my $decrypted = $self->decrypt;

   my @results = ();
   my @lines = split(/\n/, $decrypted);
   for (@lines) {
      push @results, $_ if /$pattern/i;
   }

   return \@results;
}

sub decrypt {
   my $self = shift;
   my ($db) = @_;

   $db ||= $self->db;
   $self->brik_help_run_undef_arg('decrypt', $db) or return;
   $self->brik_help_run_file_not_found('decrypt', $db) or return;

   my $read = $self->read($db) or return;

   my $ca = Metabrik::Crypto::Aes->new_from_brik_init($self) or return;

   my $decrypted = $ca->decrypt($read) or return;

   return $decrypted;
}

sub encrypt {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encrypt', $data) or return;

   my $ca = Metabrik::Crypto::Aes->new_from_brik_init($self) or return;

   my $encrypted = $ca->encrypt($data) or return;

   return $encrypted;
}

sub save {
   my $self = shift;
   my ($data, $db) = @_;

   $db ||= $self->db;
   $self->brik_help_run_undef_arg('save', $data) or return;
   $self->brik_help_run_undef_arg('save', $db) or return;

   $self->write($data, $db) or return;

   return $db;
}

1;

__END__

=head1 NAME

Metabrik::Database::Keystore - database::keystore Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
