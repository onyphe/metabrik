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
         db => [ qw(keystore_db) ],
      },
      commands => {
         search => [ qw(pattern) ],
         decrypt => [ qw(keystore_db|OPTIONAL) ],
         encrypt => [ qw($data) ],
         save => [ qw($data keystore_db|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Crypto::Aes' => [ ],
      },
   };
}

sub search {
   my $self = shift;
   my ($pattern) = @_;

   if (! defined($self->db)) {
      return $self->log->error($self->brik_help_set('db'));
   }

   if (! defined($pattern)) {
      return $self->log->error($self->brik_help_run('search'));
   }

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
   if (! defined($db)) {
      return $self->log->error($self->brik_help_set('db'));
   }

   my $read = $self->read($db)
      or return $self->log->error("decrypt: read failed");

   my $crypto_aes = Metabrik::Crypto::Aes->new_from_brik($self) or return;

   my $decrypted = $crypto_aes->decrypt($read)
      or return $self->log->error("decrypt: decrypt failed");

   return $decrypted;
}

sub encrypt {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('encrypt'));
   }

   my $crypto_aes = Metabrik::Crypto::Aes->new_from_brik($self) or return;

   my $encrypted = $crypto_aes->encrypt($data)
      or return $self->log->error("encrypt: encrypt failed");

   return $encrypted;
}

sub save {
   my $self = shift;
   my ($data, $db) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('save'));
   }

   $db ||= $self->db;

   $self->write($data, $db)
      or return $self->log->error("save: write failed");

   return $db;
}

1;

__END__

=head1 NAME

Metabrik::Database::Keystore - database::keystore Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
