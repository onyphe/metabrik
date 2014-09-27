#
# $Id: Meby.pm 89 2014-09-17 20:29:29Z gomor $
#
package Metabricky::Brick::Shell::Meby;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   echo
   shell
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

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

sub revision {
   return '$Revision$';
}

sub require_modules {
   return {
      'Metabricky::Ext::Shell' => [],
   };
}

sub help {
   return {
      'set:echo' => '<0|1>',
      'run:version' => '',
      'run:title' => '<title>',
      'run:cmd' => '<cmd>',
      'run:cmdloop' => '',
      'run:script' => '<script>',
      'run:shell' => '<command> [ <arg1:arg2:..:argN> ]',
      'run:system' => 'system <command> [ <arg1:arg2:..:argN> ]',
      'run:history' => '[ <number> ]',
      'run:write_history' => '',
      'run:cd' => '[ <path> ]',
      'run:pwd' => '',
      'run:pl' => '<code>',
      'run:su' => '',
      'run:help' => '[ <cmd> ]',
      'run:show' => '',
      'run:load' => '<brick>',
      'run:set' => '<brick> <attribute> <value>',
      'run:get' => '[ <brick> ] [ <attribute> ]',
      'run:run' => '<brick> <command> [ <arg1:arg2:..:argN> ]',
      'run:exit' => '',
   };
}

sub default_values {
   return {
      echo => 1,
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   $Metabricky::Ext::Shell::CONTEXT = $self->context;

   my $shell = Metabricky::Ext::Shell->new;
   $shell->echo($self->echo);
   $shell->debug($self->debug);

   $self->shell($shell);

   return $self;
}

sub version {
   my $self = shift;

   $self->shell->run_version(@_);

   return 1;
}

sub title {
   my $self = shift;

   $self->shell->run_title(@_);

   return 1;
}

sub system {
   my $self = shift;

   $self->shell->run_system(@_);

   return 1;
}

sub history {
   my $self = shift;

   $self->shell->run_history(@_);

   return 1;
}

sub write_history {
   my $self = shift;

   $self->shell->run_write_history(@_);

   return 1;
}

sub cd {
   my $self = shift;

   $self->shell->run_cd(@_);

   return 1;
}

sub pwd {
   my $self = shift;

   $self->shell->run_pwd(@_);

   return 1;
}

sub pl {
   my $self = shift;

   $self->shell->run_pl(@_);

   return 1;
}

sub su {
   my $self = shift;

   $self->shell->run_su(@_);

   return 1;
}

sub show {
   my $self = shift;

   $self->shell->run_show(@_);

   return 1;
}

sub load {
   my $self = shift;

   $self->shell->run_load(@_);

   return 1;
}

sub set {
   my $self = shift;

   $self->shell->run_set(@_);

   return 1;
}

sub get {
   my $self = shift;

   $self->shell->run_get(@_);

   return 1;
}

sub run {
   my $self = shift;

   $self->shell->run_run(@_);

   return 1;
}

sub exit {
   my $self = shift;

   $self->shell->run_exit(@_);

   return 1;
}
sub cmd {
   my $self = shift;

   $self->shell->cmd(@_);

   return 1;
}

sub cmdloop {
   my $self = shift;

   $self->shell->cmdloop(@_);

   return 1;
}

sub script {
   my $self = shift;

   $self->shell->run_script(@_);

   return 1;
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

=head3 B<$Metabricky::Brick::Shell::Meby::CONTEXT>

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
