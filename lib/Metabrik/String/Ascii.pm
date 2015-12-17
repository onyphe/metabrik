#
# $Id$
#
# string::ascii Brik
#
package Metabrik::String::Ascii;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable encode decode) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         from_dec => [ qw($data) ],
      },
      require_modules => {
      },
   };
}

sub from_dec {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('from_dec'));
   }

   my @data = ();
   if (ref($data) eq 'ARRAY') {
      for my $this (@$data) {
         if ($this =~ /^\d+$/) {
            push @data, $this;
         }
         else {
            $self->log->warning("from_dec: data [$this] is not decimal, skipping");
         }
      }
   }
   elsif (! ref($data)) {
      if ($data =~ /^\d+$/) {
         push @data, $data;
      }
      else {
         $self->log->warning("from_dec: data [$data] is not decimal, skipping");
      }
   }

   my $str = '';
   for (@data) {
      $str .= sprintf("%c", $_);
   }

   return $str;
}

1;

__END__

=head1 NAME

Metabrik::String::Ascii - string::ascii Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
