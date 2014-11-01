#
# $Id$
#
# shell::rc Brik
#
package Metabrik::Shell::Rc;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell rc) ],
      attributes => {
         rc_file => [ qw(file) ],
      },
      commands => {
         load => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         rc_file => $self->global->homedir.'/.metabrik_rc',
      },
   };
}

sub load {
   my $self = shift;

   my $rc_file = $self->rc_file;

   if (! -f $rc_file) {
      return $self->log->error("load: can't find rc file [$rc_file]");
   }

   my @lines = ();
   my @multilines = ();
   open(my $in, '<', $rc_file)
         or return $self->log->error("local: can't open rc file [$rc_file]: $!");
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
