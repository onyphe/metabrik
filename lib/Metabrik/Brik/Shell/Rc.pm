#
# $Id$
#
# shell::rc Brik
#
package Metabrik::Brik::Shell::Rc;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      rc_file => [],
   };
}

sub help {
   return {
      'set:rc_file' => '<file>',
      'run:load' => '',
   };
}

sub default_values {
   my $self = shift;

   return {
      rc_file => $self->global->homedir.'/.metabrik_rc',
   };
}

sub load {
   my $self = shift;

   my $rc_file = $self->rc_file;

   if (! -f $rc_file) {
      return $self->log->info("load: can't find rc file [$rc_file]");
   }

   my @lines = ();
   open(my $in, '<', $rc_file)
         or return $self->log->error("local: can't open rc file [$rc_file]: $!");
   while (defined(my $line = <$in>)) {
      next if ($line =~ /^\s*#/);  # Skip comments
      chomp($line);
      push @lines, $line;
   }
   close($in);

   $self->debug && $self->log->debug("load: success");

   return \@lines;
}

1;

__END__
