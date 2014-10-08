#
# $Id$
#
# shell::script Brik
#
package Metabrik::Brik::Shell::Script;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell script) ],
      attributes => {
         file => [ qw(SCALAR) ],
      },
      attributes_default => {
         file => 'script.brik',
      },
   };
}

sub help {
   return {
      'set:file' => '<file>',
      'run:load' => '',
   };
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

1;

__END__
