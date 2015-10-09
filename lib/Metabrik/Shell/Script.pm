#
# $Id$
#
# shell::script Brik
#
package Metabrik::Shell::Script;
use strict;
use warnings;

our $VERSION = '1.10';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell script) ],
      attributes => {
         file => [ qw(file) ],
      },
      attributes_default => {
         file => 'script.meta',
      },
      commands => {
         load => [ qw(input_file|OPTIONAL) ],
         exec => [ qw($line_list) ],
      },
   };
}

sub load {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->file;

   if (! -f $file) {
      return $self->log->info("load: can't find file [$file]");
   }

   my @lines = ();
   open(my $in, '<', $file)
      or return $self->log->error("load: can't open file [$file]: $!");
   while (defined(my $line = <$in>)) {
      chomp($line);
      push @lines, $line;
   }
   close($in);

   $self->debug && $self->log->debug("load: success");

   return \@lines;
}

sub exec {
   my $self = shift;
   my ($lines) = @_;

   if (! defined($lines)) {
      return $self->log->error($self->brik_help_run('exec'));
   }

   if (ref($lines) ne 'ARRAY') {
      return $self->log->error("exec: must give an ARRAYREF as argument");
   }

   my $shell = $self->shell;

   $shell->cmdloop($lines);

   return 1;
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
