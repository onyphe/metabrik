#
# $Id$
#
# Find plugin
#
package Plashy::Plugin::Find;
use strict;
use warnings;

use base qw(Plashy::Plugin);

our @AS = qw(
   path
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use File::Find;

#sub require_modules {
#   return [
#      'File::Find',
#   ];
#}

#sub help {
#   return {
#      'find' => 'run find files <directories> <pattern>',
#   };
#}
sub help {
   print "set find path <director1:directory2:..:directoryN>\n";
   print "\n";
   print "run find files <dirpattern> <filepattern>\n";
}

#sub files_require_command {
#}

#sub files_require_arg {
#   return [
#      'directories', 'pattern',
#   ];
#}

sub files {
   my $self = shift;
   my ($dirpattern, $filepattern) = @_;

   my $path = $self->path;
   if (! defined($path)) {
      die("set find path <director1:directory2:..:directoryN>\n");
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

Plashy::Plugin::Find - plugin to find some files using pattern matching

=head1 SYNOPSIS

   # From a module

   use Plashy::Plugin::Find;

   my $path = join(':', @INC);

   my $plugin = Plashy::Plugin::Find->new;
   $plugin->path($path);

   my $found = $plugin->find('/lib/Plashy/Plugin$', '.pm$');
   for my $file (@$found) {
      print "$file\n";
   }

   # From the Shell

   > my $path = join(':', @INC)
   > set find path $path
   > run find files /lib/Plashy/Plugin$ .pm$

=head1 DESCRIPTION

Plugin to find some files using pattern matching.

=head2 ATTRIBUTES

=head3 B<path> (directory1:directory2:..:directoryN)

=head2 METHODS

=head3 B<find> (directory, pattern)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
