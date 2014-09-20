#
# $Id: Find.pm 89 2014-09-17 20:29:29Z gomor $
#
# Find brick
#
package Metabricky::Brick::File::Find;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   path
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'File::Find',
   ];
}

sub help {
   return {
      'set:path' => '<director1:directory2:..:directoryN>',
      'run:files' => '<dirpattern> <filepattern>',
   };
}

sub files {
   my $self = shift;
   my ($dirpattern, $filepattern) = @_;

   my $path = $self->path;
   if (! defined($path)) {
      return $self->log->info($self->help_set('path'));
   }

   my @path_list = split(':', $path);

   my @found = ();

   $dirpattern =~ s/\//\\\//g;

   my $sub = sub {
      my $dir = $File::Find::dir;
      my $file = $_;
      #print "dirpattern [$dirpattern]\n";
      #print "dir [$dir]\n";
      #print "filepattern [$filepattern]\n";
      #print "file [$file]\n";
      if ($dir =~ /$dirpattern/ && $file =~ /$filepattern/) {
         push @found, "$dir/$file";
      }
   };

   {
      no warnings 'File::Find';
      find($sub, @path_list);
   };

   my %h = map { $_ => 1 } @found;

   return \@found;
}

1;

__END__

=head1 NAME

Metabricky::Brick::File::Find - brick to find some files using pattern matching

=head1 SYNOPSIS

   # From a module

   use Metabricky::Brick::File::Find;

   my $path = join(':', @INC);

   my $brick = Metabricky::Brick::File::Find->new;
   $brick->path($path);

   my $found = $brick->find('/lib/Metabricky/Brick$', '.pm$');
   for my $file (@$found) {
      print "$file\n";
   }

   # From meby shell

   > my $path = join(':', @INC)
   > set file::find path $path
   > run file::find files /lib/Metabricky/Brick$ .pm$

=head1 DESCRIPTION

Brick to find some files using pattern matching.

=head2 ATTRIBUTES

=head3 B<path> (directory1:directory2:..:directoryN)

=head2 COMMANDS

=head3 B<find> (directory, pattern)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
