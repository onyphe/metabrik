#
# $Id$
#
# Template brick
#
package Metabricky::Brick::Core::Template;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   attribute1
   attribute2
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#use Template::Some::Module;

sub help {
   print "set core::template attribute1 <value>\n";
   print "set core::template attribute2 <value>\n";
   print "\n";
   print "run core::template command1 <argument1> <argument2>\n";
   print "run core::template command2 <argument1> <argument2>\n";
}

sub default_values {
   my $self = shift;

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
      die("run core::template command1 <argument1> <argument2>\n");
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub command2 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      die("run core::template command2 <argument1> <argument2>\n");
   }

   my $do_something = "you should do something";

   return $do_something;
}

1;

__END__

=head1 NAME

Metabricky::Brick::Core::Template - template to write a new Metabricky brick

=head1 SYNOPSIS

   $ cp lib/Metabricky/Brick/Core/Template.pm ~/myMetabricky/lib/Brick/Category/Mybrick.pm
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
