#
# $Id$
#
# database::keystore Brik
#
package Metabrik::Brik::Database::Keystore;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      db => [],
   };
}

sub require_loaded {
   return {
      'crypto::aes' => [],
      'file::read' => [],
   };
}

sub help {
   return {
      'set:db' => '<file>',
      'run:search' => '<pattern>',
   };
}
      #'run:add' => '<data>',
      #'run:remove' => '<data>',

sub search {
   my $self = shift;
   my ($pattern) = @_;

   if (! defined($self->db)) {
      return $self->log->info($self->help_set('db'));
   }

   if (! defined($pattern)) {
      return $self->log->info($self->help_run('search'));
   }

   $self->context->set('file::read', 'input', $self->db) or return;
   my $read = $self->context->run('file::read', 'text') or return;

   my $decrypted = $self->context->run('crypto::aes', 'decrypt', $read) or return;

   my @lines = split(/\n/, $decrypted);
   for (@lines) {
      print "$_\n" if /$pattern/i;
   }

   return 1;
}

1;

__END__
