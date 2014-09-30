#
# $Id$
#
# string::gzip Brick
#
package Metabricky::Brick::String::Gzip;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   data
   memory_limit
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return {
      'Gzip::Faster' => [],
   };
}

sub help {
   return {
      'set:data' => '<data>',
      'set:memory_limit' => '<size>',
      'run:gunzip' => '<data>',
      'run:gzip' => '<data>',
   };
}

sub default_values {
   return {
      memory_limit => '1_000_000_000',
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   # Do your init here

   return $self;
}

sub gunzip {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->info($self->help_run('gunzip'));
   }

   $self->debug && $self->log->debug("gunzip: length[".length($data)."]");

   $self->debug && $self->log->debug("gunzip: starting");
   my $plain = Gzip::Faster::gunzip($data)
      or return $self->log->error("gunzip: error");
   $self->debug && $self->log->debug("gunzip: finished");

   $self->debug && $self->log->debug("gunzip: length[".length($plain)."]");

   return \$plain;
}

sub gzip {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->info($self->help_run('gzip'));
   }

   my $gzipped = Gzip::Faster::gzip($data)
      or return $self->log->error("gzip: error");

   return \$gzipped;
}

1;

__END__

=head1 NAME

Metabricky::Brick::Example::Template - template to write a new Metabricky brick

=head1 SYNOPSIS

   $ cp lib/Metabricky/Brick/Example/Template.pm ~/myMetabricky/lib/Brick/Category/Mybrick.pm
   $ vi ~/myMetabricky/lib/Brick/Category/Mybrick.pm

   # From a module

   use Metabricky::Brick::File::Find;

   my $path = join(':', @INC);
   my $brick = Metabricky::Brick::File::Find->new;
   my $found = $brick->find($path, '/lib/Metabricky/Brick$', '.pm$');
   for my $file (@$found) {
      print "$file\n";
   }

   # From meby shell

   > my $path = join(':', @INC)
   > set file::find path $path
   > run file::find files /lib/Metabricky/Brick$ .pm$

=head1 DESCRIPTION

Template to write a new Metabricky brick.

=head2 COMMANDS

=head3 B<help>

=head3 B<default_values>

=head3 B<init>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
