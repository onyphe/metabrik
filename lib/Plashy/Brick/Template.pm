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

=head1 NAME

Plashy::Plugin::Template - template to write a new Plashy plugin

=head1 SYNOPSIS

   $ cp lib/Plashy/Plugin/Template.pm ~/myplashy/lib/Plugin/Myplugin.pm
   $ vi ~/myplashy/lib/Plugin/Myplugin.pm

   # From a module

   use Plashy::Plugin::Find;

   my $path = join(':', @INC);
   my $plugin = Plashy::Plugin::Find->new;
   my $found = $plugin->find($path, '/lib/Plashy/Plugin$', '.pm$');
   for my $file (@$found) {
      print "$file\n";
   }

   # From the Shell

   > my $path = join(':', @INC)
   > set find path $path
   > run find files /lib/Plashy/Plugin$ .pm$

=head1 DESCRIPTION

Template to write a new Plashy plugin.

=head2 METHODS

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
