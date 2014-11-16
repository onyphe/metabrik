#
# $Id$
#
# database::keystore Brik
#
package Metabrik::Database::Keystore;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      attributes => {
         db => [ qw(keystore_db) ],
      },
      commands => {
         search => [ qw(pattern) ],
      },
      require_used => {
         'crypto::aes' => [ ],
         'file::read' => [ ],
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

   my $context = $self->context;

   $context->set('file::read', 'input', $self->db);
   $context->run('file::read', 'open') or return;
   my $read = $context->run('file::read', 'readall')
      or return $self->log->error("search: file::read: readall");
   $context->run('file::read', 'close');

   my $decrypted = $context->run('crypto::aes', 'decrypt', $read)
      or return $self->log->error("search: crypto::aes: decrypt");

   my @lines = split(/\n/, $decrypted);
   for (@lines) {
      print "$_\n" if /$pattern/i;
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Database::Keystore - database::keystore Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
