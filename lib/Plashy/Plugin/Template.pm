#
# $Id$
#
# Template plugin
#
package Plashy::Plugin::Template;
use strict;
use warnings;

use base qw(Plashy::Plugin);

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
   print "run template method1 <argument1> <argument2>\n";
   print "run template method2 <argument1> <argument2>\n";
}

sub method1 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      die($self->help);
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub method2 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      die($self->help);
   }

   my $do_something = "you should do something";

   return $do_something;
}

1;

__END__
