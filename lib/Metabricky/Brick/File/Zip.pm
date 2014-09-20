#
# $Id: Zip.pm 89 2014-09-17 20:29:29Z gomor $
#
# Zip brick
#
package Metabricky::Brick::File::Zip;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   input
   output
   destdir
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub help {
   return {
      'set:input' => '<file>',
      'set:output' => '<file>',
      'set:destdir' => '<destdir>',
      'run:uncompress' => '',
      'run:compress' => '',
   };
}

sub default_values {
   my $self = shift;

   return {
      destdir => $self->bricks->{'core::global'}->datadir,
   };
}

sub uncompress {
   my $self = shift;
   my ($destdir) = @_;

   my $input = $self->input;
   if (! defined($input)) {
      return $self->log->info($self->help_set('input'));
   }

   my $dir = $self->destdir;
   if (! defined($dir)) {
      return $self->log->info($self->help_set('destdir'));
   }

   # XXX: dirty for now
   for my $path (split(':', $ENV{PATH})) {
      if (-f "$path/unzip") {
         my $ret = `$path/unzip -o $input -d $dir/`;
         print "$ret\n";
         return !$?;
      }
   }

   return $self->log->error("unzip binary not found");
}

1;

__END__
