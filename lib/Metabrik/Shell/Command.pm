#
# $Id$
#
# shell::command Brik
#
package Metabrik::Shell::Command;
use strict;
use warnings;

our $VERSION = '1.06';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell command system) ],
      attributes => {
         as_array => [ qw(0|1) ],
         as_matrix => [ qw(0|1) ],
         capture_stderr => [ qw(0|1) ],
      },
      commands => {
         system => [ qw(command) ],
         capture => [ qw(command) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         as_array => 1,
         as_matrix => 0,
         capture_stderr => 1,
      },
   };
}

sub system {
   my $self = shift;
   my ($cmd, @args) = @_;

   if (! defined($cmd)) {
      return $self->log->error($self->brik_help_run('system'));
   }

   # Remove undefined values from arguments
   my @new;
   for (@args) {
      if (defined($_)) {
         push @new, $_;
      }
   }

   my $command = join(' ', $cmd, @new);
   my @toks = split(/\s+/, $command);
   my $bin = $toks[0];

   my @path = split(':', $ENV{PATH});
   if (! -f $bin) {  # If file is not directly found
      for my $path (@path) {
         if (-f "$path/$bin") {
            $bin = "$path/$bin";
            last;
         }
      }
   }
   $toks[0] = $bin;

   if (! -f $bin) {
      return $self->log->error("system: program [$bin] not found in PATH");
   }

   $command = join(' ', @toks);
   my $r = CORE::system($command);

   return defined($r) ? 1 : 0;
}

sub capture {
   my $self = shift;
   my ($cmd, @args) = @_;

   if (! defined($cmd)) {
      return $self->log->error($self->brik_help_run('capture'));
   }

   # Remove undefined values from arguments
   my @new;
   for (@args) {
      if (defined($_)) {
         push @new, $_;
      }
   }

   my $command = join(' ', $cmd, @new);
   my @toks = split(/\s+/, $command);
   my $bin = $toks[0];

   my @path = split(':', $ENV{PATH});
   if (! -f $bin) {  # If file is not directly found
      for my $path (@path) {
         if (-f "$path/$bin") {
            $bin = "$path/$bin";
            last;
         }
      }
   }
   $toks[0] = $bin;

   if (! -f $bin) {
      return $self->log->error("system: program [$bin] not found in PATH");
   }

   $command = join(' ', @toks);

   my $out = $self->capture_stderr ? `$command 2>&1` : `$command`;
   $out ||= 'undef';
   chomp($out);
   if ($?) {
      return $self->log->error("capture: exec failed [$out]");
   }

   # as_matrix has precedence over as_array (because as_array is the default)
   if (! $self->as_matrix && $self->as_array) {
      $out = [ split(/\n/, $out) ];
   }
   elsif ($self->as_matrix) {
      my @matrix = ();
      for my $this (split(/\n/, $out)) {
         push @matrix, [ split(/\s+/, $this) ];
      }
      $out = \@matrix;
   }

   return $out;
}

1;

__END__

=head1 NAME

Metabrik::Shell::Command - shell::command Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
