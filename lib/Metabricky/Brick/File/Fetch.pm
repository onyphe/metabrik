#
# $Id: Fetch.pm 89 2014-09-17 20:29:29Z gomor $
#
# Fetch brick
#
package Metabricky::Brick::File::Fetch;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   output
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub help {
   return [
      'set file::fetch output <file>',
      'run file::fetch get <uri>',
   ];
}

sub get {
   my $self = shift;
   my ($uri) = @_;

   my $output = $self->output;
   if (! defined($output)) {
      return $self->log->info("set file::fetch output <file>");
   }

   if (! defined($uri)) {
      return $self->log->info("run file::fetch get <uri>");
   }

   # XXX: dirty for now
   for my $path (split(':', $ENV{PATH})) {
      if (-f "$path/wget") {
         #print "DEBUG $path/wget --output-document=$output $uri\n";
         my $ret = `$path/wget --output-document=$output $uri`;
         return !$ret;
      }
   }

   return $self->log->error("wget binary not found");
}

1;

__END__
