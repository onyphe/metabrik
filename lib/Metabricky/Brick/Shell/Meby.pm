#
# $Id$
#
package Metabricky::Brick::Shell::Meby;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   echo
   newline
   commands
   shell
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Metabricky::Ext::Shell;

{
   no warnings;

   # We redefine some accessors so we can write the value to Ext::Shell

   *echo = sub {
      my $self = shift;
      my ($value) = @_;

      if (defined($value)) {
         # set shell echo attribute only when is has been populated
         if (defined($self->shell)) {
            return $self->shell->echo($self->{echo} = $value);
         }

         return $self->{echo} = $value;
      }

      return $self->{echo};
   };

   *newline = sub {
      my $self = shift;
      my ($value) = @_;

      if (defined($value)) {
         # set shell newline attribute only when is has been populated
         if (defined($self->shell)) {
            return $self->shell->newline($self->{newline} = $value);
         }

         return $self->{newline} = $value;
      }

      return $self->{newline};
   };

   *commands = sub {
      my $self = shift;
      my ($value) = @_;

      if (defined($value)) {
         # set shell commands attribute only when is has been populated
         if (defined($self->shell)) {
            return $self->shell->commands($self->{commands} = $value);
         }

         return $self->{commands} = $value;
      }

      return $self->{commands};
   };

   *debug = sub {
      my $self = shift;
      my ($value) = @_;

      if (defined($value)) {
         # set shell debug attribute only when is has been populated
         if (defined($self->shell)) {
            return $self->shell->debug($self->{debug} = $value);
         }

         return $self->{debug} = $value;
      }

      return $self->{debug};
   };
}

sub help {
   print "set shell::meby echo <0|1>\n";
   print "set shell::meby newline <0|1>\n";
   print "set shell::meby commands <command1:command2:..:commandN>\n";
   print "\n";
   print "run shell::meby cmdloop\n";
   print "run shell::meby script <script>\n";
}

sub default_values {
   my $self = shift;

   return {
      echo => 1,
      newline => 1,
      commands => 'vi:ls:w:top:less:cat:find:grep:nc:cpanm',
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   $Metabricky::Ext::Shell::Bricks = $self->bricks;

   my $shell = Metabricky::Ext::Shell->new;
   $shell->echo($self->echo);
   $shell->newline($self->newline);
   $shell->commands($self->commands);
   $shell->debug($self->debug);

   $self->shell($shell);

   return $self;
}

sub cmdloop {
   my $self = shift;

   return $self->shell->cmdloop;
}

sub script {
   my $self = shift;
   my ($script) = @_;

   return $self->shell->cmd("script $script");
}

1;

__END__

=head1 NAME

Metabricky::Brick::Shell::Meby - the Metabricky shell

=head1 SYNOPSIS

   # XXX: TODO

=head1 DESCRIPTION

Interactive use of the Metabricky shell.

=head2 GLOBAL VARIABLES

=head3 B<$Metabricky::Brick::Shell::Meby::Bricks>

Specify a log object. Must be an object inherited from L<Metabricky::Log>.

=head2 COMMANDS

=head3 B<new>

=head1 SEE ALSO

L<Metabricky::Log>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
