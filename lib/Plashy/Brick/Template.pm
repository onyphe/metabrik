#
# $Id$
#
# Template brick
#
package Plashy::Brick::Template;
use strict;
use warnings;

use base qw(Plashy::Brick);

our @AS = qw(
   variable1
   variable2
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#use Template::Some::Module;

sub help {
   print "set template variable1 <value>\n";
   print "set template variable2 <value>\n";
   print "\n";
   print "run template command1 <argument1> <argument2>\n";
   print "run template command2 <argument1> <argument2>\n";
}

sub default_values {
   my $self = shift;

   return {
      variable1 => 'value1',
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
      die("run template command1 <argument1> <argument2>\n");
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub command2 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      die("run template command2 <argument1> <argument2>\n");
   }

   my $do_something = "you should do something";

   return $do_something;
}

1;

__END__

=head1 NAME

Plashy::Brick::Template - template to write a new Plashy brick

=head1 SYNOPSIS

   $ cp lib/Plashy/Brick/Template.pm ~/myplashy/lib/Brick/Mybrick.pm
   $ vi ~/myplashy/lib/Brick/Mybrick.pm

   # From a module

   use Plashy::Brick::Find;

   my $path = join(':', @INC);
   my $brick = Plashy::Brick::Find->new;
   my $found = $brick->find($path, '/lib/Plashy/Brick$', '.pm$');
   for my $file (@$found) {
      print "$file\n";
   }

   # From the Shell

   > my $path = join(':', @INC)
   > set find path $path
   > run find files /lib/Plashy/Brick$ .pm$

=head1 DESCRIPTION

Template to write a new Plashy brick.

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
