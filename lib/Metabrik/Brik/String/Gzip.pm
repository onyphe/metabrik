#
# $Id$
#
# string::gzip Brik
#
package Metabrik::Brik::String::Gzip;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      data => [],
      memory_limit => [],
   };
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

Metabrik::Brik::Example::Template - template to write a new Metabriky Brik

=head1 SYNOPSIS

   $ cp lib/Metabrik/Brik/Example/Template.pm ~/myMetabriky/lib/Brik/Category/Mybrik.pm
   $ vi ~/myMetabrik/lib/Brik/Category/Mybrik.pm

   # From a module

   use Metabrik::Brik::File::Find;

   my $path = join(':', @INC);
   my $brik = Metabrik::Brik::File::Find->new;
   my $found = $brik->find($path, '/lib/Metabrik/Brik$', '.pm$');
   for my $file (@$found) {
      print "$file\n";
   }

   # From Metabrik shell

   > my $path = join(':', @INC)
   > set file::find path $path
   > run file::find files /lib/Metabrik/Brik$ .pm$

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

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
