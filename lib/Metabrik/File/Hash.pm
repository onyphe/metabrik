#
# $Id$
#
# file::hash Brik
#
package Metabrik::File::Hash;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
      },
      commands => {
         sha1 => [ qw(input|OPTIONAL) ],
         sha256 => [ qw(input|OPTIONAL) ],
         md5 => [ qw(input|OPTIONAL) ],
      },
      require_modules => {
         'Crypt::Digest' => [ ],
      },
   };
}

sub sha1 {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('sha1'));
   }

   if (! -f $input) {
      return $self->log->error("sha1: file [$input] not found");
   }

   eval("use Crypt::Digest::SHA1 qw(sha1_file_hex);");
   if ($@) {
      chomp($@);
      return $self->log->error("sha1: unable to load function: $@");
   }

   return Crypt::Digest::SHA1::sha1_file_hex($input);
}

sub sha256 {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('sha256'));
   }

   if (! -f $input) {
      return $self->log->error("sha256: file [$input] not found");
   }

   eval("use Crypt::Digest::SHA256 qw(sha256_file_hex);");
   if ($@) {
      chomp($@);
      return $self->log->error("sha256: unable to load function: $@");
   }

   return Crypt::Digest::SHA256::sha256_file_hex($input);
}

sub md5 {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('md5'));
   }

   if (! -f $input) {
      return $self->log->error("md5: file [$input] not found");
   }

   eval("use Crypt::Digest::MD5 qw(md5_file_hex);");
   if ($@) {
      chomp($@);
      return $self->log->error("md5: unable to load function: $@");
   }

   return Crypt::Digest::MD5::md5_file_hex($input);
}

1;

__END__

=head1 NAME

Metabrik::File::Hash - file::hash Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
