#
# $Id$
#
# string::hash Brik
#
package Metabrik::String::Hash;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable sha sha1 sha256 sha512 md5 md5sum sum) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         sha1 => [ qw(data) ],
         sha256 => [ qw(data) ],
         sha512 => [ qw(data) ],
         md5 => [ qw(data) ],
         mmh3 => [ qw(data signed|OPTIONAL) ],
      },
      require_modules => {
         'Crypt::Digest' => [ ],
         'Digest::MurmurHash3' => [ qw(murmur32) ],
      },
   };
}

sub _hash {
   my $self = shift;
   my ($function, $data) = @_;

   $self->brik_help_run_undef_arg($function, $data) or return;

   eval("use Crypt::Digest qw(digest_data_hex);");
   if ($@) {
      chomp($@);
      return $self->log->error("$function: unable to load function: $@");
   }

   my $hash;
   eval {
      $hash = Crypt::Digest::digest_data_hex(uc($function), $data);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("$function: unable to compute hash: $@");
   }

   return $hash;
}

sub sha1 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('sha1', $data);
}

sub sha256 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('sha256', $data);
}

sub sha512 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('sha512', $data);
}

sub md5 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('md5', $data);
}

sub mmh3 {
   my $self = shift;
   my ($data, $signed) = @_;

   $signed ||= 0;

   my $hash;
   eval {
      $hash = Digest::MurmurHash3::murmur32($data, 0, $signed);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("mmh3: unable to compute hash: $@");
   }

   return $hash;
}

1;

__END__

=head1 NAME

Metabrik::File::Hash - file::hash Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
