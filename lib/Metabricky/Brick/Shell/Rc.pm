#
# $Id: Template.pm 89 2014-09-17 20:29:29Z gomor $
#
# shell::rc Brick
#
package Metabricky::Brick::Shell::Rc;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   rc_file
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
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
      rc_file => $self->global->homedir.'/.meby_rc',
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
