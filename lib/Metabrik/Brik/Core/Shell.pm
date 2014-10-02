#
# $Id$
#
# core::shell Brik
#
package Metabrik::Brik::Core::Shell;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      echo => [],
      _shell => [],
   };
}

{
   no warnings;   # Avoid redefine warnings

   # We redefine some accessors so we can write the value to Ext::Shell

   *echo = sub {
      my $self = shift;
      my ($value) = @_;

      if (defined($value)) {
         # set shell echo attribute only when is has been populated
         if (defined($self->_shell)) {
            return $self->_shell->echo($self->{echo} = $value);
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
         if (defined($self->_shell)) {
            return $self->_shell->debug($self->{debug} = $value);
         }

         return $self->{debug} = $value;
      }

      return $self->{debug};
   };
}

sub require_modules {
   return {
      'Metabrik::Ext::Shell' => [],
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
      'run:load' => '<brik>',
      'run:set' => '<brik> <attribute> <value>',
      'run:get' => '[ <brik> ] [ <attribute> ]',
      'run:run' => '<brik> <command> [ <arg1:arg2:..:argN> ]',
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

   $Metabrik::Ext::Shell::CTX = $self->context;

   my $shell = Metabrik::Ext::Shell->new;
   $shell->echo($self->echo);
   $shell->debug($self->debug);

   $self->_shell($shell);

   return $self;
}

sub title {
   my $self = shift;

   $self->_shell->run_title(@_);

   return 1;
}

sub system {
   my $self = shift;

   $self->_shell->run_system(@_);

   return 1;
}

sub history {
   my $self = shift;

   $self->_shell->run_history(@_);

   return 1;
}

sub write_history {
   my $self = shift;

   $self->_shell->run_write_history(@_);

   return 1;
}

sub cd {
   my $self = shift;

   $self->_shell->run_cd(@_);

   return 1;
}

sub pl {
   my $self = shift;

   $self->_shell->run_pl(@_);

   return 1;
}

sub su {
   my $self = shift;

   $self->_shell->run_su(@_);

   return 1;
}

sub show {
   my $self = shift;

   $self->_shell->run_show(@_);

   return 1;
}

sub load {
   my $self = shift;

   $self->_shell->run_load(@_);

   return 1;
}

sub set {
   my $self = shift;

   $self->_shell->run_set(@_);

   return 1;
}

sub get {
   my $self = shift;

   $self->_shell->run_get(@_);

   return 1;
}

sub run {
   my $self = shift;

   $self->_shell->run_run(@_);

   return 1;
}

sub exit {
   my $self = shift;

   $self->_shell->run_exit(@_);

   return 1;
}

sub cmd {
   my $self = shift;

   $self->_shell->cmd(@_);

   return 1;
}

sub cmdloop {
   my $self = shift;

   $self->_shell->cmdloop(@_);

   return 1;
}

sub script {
   my $self = shift;

   $self->_shell->run_script(@_);

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Brik::Core::Shell - The Metabrik Shell

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
