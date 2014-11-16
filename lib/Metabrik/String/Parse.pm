#
# $Id: Parse.pm 142 2014-09-29 20:23:55Z gomor $
#
# string::parse Brik
#
package Metabrik::String::Parse;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable parse string) ],
      commands => {
         identify => [ qw(string) ],
         to_array => [ qw(0|1) ],
         to_matrix => [ qw(0|1) ],
      },
   };
}

sub to_array {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('to_array'));
   }

   my @array = split(/\n/, $data);

   return \@array;
}

sub to_matrix {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('to_matrix'));
   }

   my $array = $self->to_array($data);

   my @matrix = ();
   for my $this (@$array) {
      push @matrix, [ split(/\s+/, $this) ];
   }

   return \@matrix;
}

sub identify {
   my $self = shift;
   my ($string) = @_;

   if (! defined($string)) {
      return $self->log->error($self->brik_help_run('identify'));
   }

   my $length = length($string);
   # Truncate to 128 Bytes
   my $subset = substr($string, 0, $length > 128 ? 128 : $length);

   my $identify = [ 'text' ]; # Default dump text string

   if ($subset =~ /^<html>/i) {
      push @$identify, 'html';
   }
   elsif ($subset =~ /^<xml /i) {
      push @$identify, 'xml';
   }
   elsif ($subset =~ /^\s*{\s+["a-zA-Z0-9:]+\s+/) {
      push @$identify, 'json';
   }
   elsif ($string =~ /^[a-zA-Z0-9+]+={1,2}$/) {
      push @$identify, 'base64';
   }
   elsif ($length == 32 && $string =~ /^[a-f0-9]+$/) {
      push @$identify, 'md5';
   }
   elsif ($length == 40 && $string =~ /^[a-f0-9]+$/) {
      push @$identify, 'sha1';
   }
   elsif ($length == 64 && $string =~ /^[a-f0-9]+$/) {
      push @$identify, 'sha256';
   }

   return $identify;
}

1;

__END__

=head1 NAME

Metabrik::String::Parse - string::parse Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
