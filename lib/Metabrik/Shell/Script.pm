#
# $Id$
#
# shell::script Brik
#
package Metabrik::Shell::Script;
use strict;
use warnings;

our $VERSION = '1.04';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell script) ],
      attributes => {
         file => [ qw(file) ],
      },
      attributes_default => {
         file => 'script.brik',
      },
      commands => {
         load => [ ],
         exec => [ qw($line_list) ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $context = $self->context;
   my $shell = $self->shell;

   $self->debug && $self->log->debug("brik_init: start");

   if ($context->is_used('shell::rc')) {
      $self->debug && $self->log->debug("brik_init: load rc file");

      my $cmd = $context->run('shell::rc', 'load');
      for (@$cmd) {
         $shell->cmd($_);
      }
   }

   $self->debug && $self->log->debug("brik_init: done");

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("brik_init: INT caught");
      $shell->run_exit;
      exit(0);
   };

   return $self->SUPER::brik_init;
}

sub load {
   my $self = shift;

   my $file = $self->file;

   if (! -f $file) {
      return $self->log->info("load: can't find file [$file]");
   }

   my @lines = ();
   my @multilines = ();
   open(my $in, '<', $file)
         or return $self->log->error("load: can't open file [$file]: $!");
   while (defined(my $this = <$in>)) {
      chomp($this);
      next if ($this =~ /^\s*#/);  # Skip comments
      next if ($this =~ /^\s*$/);  # Skip blank lines

      push @multilines, $this;

      # First line of a multiline
      if ($this =~ /\\\s*$/) {
         next;
      }

      # Multiline edition finished, we can remove the `\' char before joining
      for (@multilines) {
         s/\\\s*$//;
      }

      $self->debug && $self->log->debug("load: multilines[@multilines]");

      my $line = join('', @multilines);
      @multilines = ();

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

   my $context = $self->context;
   my $shell = $self->shell;

   for (@$lines) {
      if (/^\s*exit\s*(\d+)\s*;/) {
         exit($1);
      }
      $shell->cmd($_);
   }

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
