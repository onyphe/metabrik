#
# $Id$
#
# file::find Brick
#
package Metabricky::Brick::File::Find;
use strict;
use warnings;

use base qw(Metabricky::Brick);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      path => [],
      recursive => [],
   };
}

use IO::All;

sub require_modules {
   return {
      'IO::All' => [],
      'File::Find' => [],
   };
}

sub default_values {
   return {
      'path' => '.',
      'recursive' => 1,
   };
}

sub help {
   return {
      'set:path' => '<director1:directory2:..:directoryN> (default: \'.\')',
      'set:recursive' => '<0|1> (default: 1)',
      'run:all' => '<dirpattern> <filepattern>',
   };
}

#sub files {
#}

#sub directories {
#}

sub all {
   my $self = shift;
   my ($dirpattern, $filepattern) = @_;

   if (! defined($dirpattern) || ! defined($filepattern)) {
      return $self->log->info($self->help_run('files'));
   }

   my @dirs = ();
   my @files = ();

   my $path = $self->path;
   my @path_list = split(':', $path);

   # Escape dirpattern if we are search for a directory hierarchy
   $dirpattern =~ s/\//\\\//g;

   # In recursive mode, we use the File::Find module
   if ($self->recursive) {
      my $dir_regex = qr/$dirpattern/;
      my $file_regex = qr/$filepattern/;
      my $dot_regex = qr/^\.$/;
      my $dot2_regex = qr/^\.\.$/;

      my $sub = sub {
         my $dir = $File::Find::dir;
         my $file = $_;
         # Skip dot and double dot directories
         if ($file =~ $dot_regex || $file =~ $dot2_regex) {
         }
         elsif ($dir =~ $dir_regex && $file =~ $file_regex) {
            push @dirs, "$dir/";
            push @files, "$dir/$file";
         }
      };

      {
         no warnings;
         File::Find::find($sub, @path_list);
      };

      my %uniq_dirs = map { $_ => 1 } @dirs;
      my %uniq_files = map { $_ => 1 } @files;
      @dirs = sort { $a cmp $b } keys %uniq_dirs;
      @files = sort { $a cmp $b } keys %uniq_files;
   }
   # In non-recusrive mode, we can use plain IO::All
   else {
      for my $path (@path_list) {
         $self->debug && $self->log->debug("all: path: $path");

         # Includes given directory
         push @dirs, $path;

         # Handle finding of directories
         my @tmp_dirs = ();
         eval {
            @tmp_dirs = io($path)->all_dirs;
         };
         if ($@) {
            if ($self->debug) {
               chomp($@);
               $self->log->debug("all: $path: dirs: $@");
            }
            return { directories => [], files => [] };
         }
         for my $this (@tmp_dirs) {
            if ($this =~ /$dirpattern/) {
               push @dirs, "$this/";
            }
         }

         # Handle finding of files
         my @tmp_files = ();
         eval {
            @tmp_files = io($path)->all_files;
         };
         if ($@) {
            if ($self->debug) {
               chomp($@);
               $self->log->debug("all: $path: files: $@");
            }
            return { directories => [], files => [] };
         }
         for my $this (@tmp_files) {
            if ($this =~ /$filepattern/) {
               push @files, "$this";
            }
         }
      }
   }

   @dirs = map { s/^\.\///; $_ } @dirs;  # Remove leading dot slash
   @files = map { s/^\.\///; $_ } @files;  # Remove leading dot slash

   return {
      directories => \@dirs,
      files => \@files,
   };
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
   $brick->recusrive(1);
   $brick->path($path);

   my $found = $brick->find('/lib/Metabricky/Brick$', '.pm$');
   for my $file (@$found) {
      print "$file\n";
   }

   # From meby shell

   > my $path = join(':', @INC)
   > set file::find path $path
   > set file::find recursive 1
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