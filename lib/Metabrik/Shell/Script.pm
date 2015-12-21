#
# $Id$
#
# shell::script Brik
#
package Metabrik::Shell::Script;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(scripting) ],
      attributes => {
         input => [ qw(file) ],
      },
      commands => {
         load => [ qw(input|OPTIONAL) ],
         exec => [ qw($line_list) ],
         load_and_exec => [ qw(input|OPTIONAL) ],
      },
   };
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_file_not_found('load', $input) or return;

   my @lines = ();
   open(my $in, '<', $input)
      or return $self->log->error("load: can't open file [$input]: $!");
   while (defined(my $line = <$in>)) {
      chomp($line);
      next if $line =~ /^\s*$/;   # Skip blank lines
      next if $line =~ /^\s*#/;   # Skip comments
      $line =~ s/^(.*)#.*$/$1/;   # Strip comments at end of line
      push @lines, "$line ";      # Add a trailing slash in case of a multiline
                                  # So when joining them, there is no unwanted concatenation
   }
   close($in);

   return \@lines;
}

sub exec {
   my $self = shift;
   my ($lines) = @_;

   $self->brik_help_run_undef_arg('exec', $lines) or return;
   $self->brik_help_run_invalid_arg('exec', $lines, 'ARRAY') or return;

   my $shell = $self->shell;

   $shell->cmdloop($lines);

   return 1;
}

sub load_and_exec {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;

   my $lines = $self->load($input) or return;
   return $self->exec($lines);
}

1;

__END__

=head1 NAME

Metabrik::Shell::Script - shell::script Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
