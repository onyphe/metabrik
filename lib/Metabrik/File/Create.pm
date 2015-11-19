#
# $Id$
#
# file::create Brik
#
package Metabrik::File::Create;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable dd) ],
      attributes => {
         output => [ qw(output) ],
         max_size => [ qw(integer) ],
      },
      attributes_default => {
         output => 'file.create',
         max_size => 10_000_000, # 10MB
      },
      commands => {
         fixed_size => [ qw(output|OPTIONAL max_size|OPTIONAL) ],
      },
      require_binaries => {
         'dd' => [ ],
      },
   };
}

sub fixed_size {
   my $self = shift;
   my ($output, $max_size) = @_;

   $output ||= $self->output;
   $max_size ||= $self->max_size;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_run('fixed_size'));
   }

   $max_size =~ s/_//g;

   my $cmd = "dd if=/dev/zero of=$output bs=1 count=$max_size";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::File::Create - file::create Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
