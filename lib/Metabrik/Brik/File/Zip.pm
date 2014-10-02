#
# $Id$
#
# file::zip brick
#
package Metabricky::Brick::File::Zip;
use strict;
use warnings;

use base qw(Metabricky::Brick);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      input => [],
      output => [],
      destdir => [],
   };
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
      destdir => $self->global->datadir,
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
