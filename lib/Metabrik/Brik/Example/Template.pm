#
# $Id$
#
# example::template Brik
#
package Metabrik::Brik::Example::Template;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      attribute1 => [],
      attribute2 => [],
   };
}

sub require_loaded {
   return {
      'some::brik' => [],
   };
}

sub require_modules {
   return {
      'Template::Some::Module' => [],
   };
}

sub help {
   return {
      'set:attribute1' => '<value>',
      'set:attribute2' => '<value>',
      'run:command1' => '<argument1> <argument2>',
      'run:command2' => '<argument1> <argument2>',
   };
}

sub default_values {
   return {
      attribute1 => 'value1',
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   # Do your init here

   return $self;
}

sub command1 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      return $self->log->info($self->help_run('command1'));
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub command2 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      return $self->log->info($self->help_run('command2'));
   }

   my $do_something = "you should do something";

   return $do_something;
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

   # From meby shell

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
