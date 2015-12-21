#
# $Id$
#
# file::ini Brik
#
package Metabrik::File::Ini;
use strict;
use warnings;

use base qw(Metabrik);

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
         encoding => 'utf8',
         overwrite => 1,
      },
      commands => {
         read => [ qw(input|OPTIONAL) ],
         write => [ qw(ini_hash output|OPTIONAL) ],
      },
      require_modules => {
         'Config::Tiny' => [ ],
         'Metabrik::String::Ini' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->encoding($self->encoding);

   my $string = $ft->read($input) or return;

   my $si = Metabrik::String::Ini->new_from_brik_init($self) or return;

   my $ini_hash = $si->decode($string) or return;

   return $ini_hash;
}

sub write {
   my $self = shift;
   my ($ini_hash, $output) = @_;

   if (! defined($ini_hash)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $output ||= $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   if (ref($ini_hash) ne 'HASH') {
      return $self->log->error("write: argument 1 must be HASHREF");
   }

   my $si = Metabrik::String::Ini->new_from_brik_init($self) or return;

   my $string = $si->encode($ini_hash) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->encoding($self->encoding);

   $ft->write($string, $output) or return;

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Ini - file::ini Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
