#
# $Id$
#
# example::template Brik
#
package Metabrik::Example::Template;
use strict;
use warnings;

use base qw(Metabrik);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(tag1 tag2) ],
      attributes => {
         attribute1 => [ qw(type) ],
         attribute2 => [ qw($type_list $type_hash) ],
      },
      attributes_default => {
         attribute1 => 10,
         attribute2 => [ qw(val1 val2) ],
      },
      commands => {
         command1 => [ qw() ],
         command2 => [ qw($type_list type) ],
      },
      require_modules => {
         'Module::Name1' => [ qw(Function1) ],
         'Module::Name2' => [ qw() ],
      },
      require_used => {
         'Brik1' => [ ],
         'Brik2' => [ ],
      },
      require_binaries => {
         'binary', => [ ],
      },
   };
}

# Warning: default attribute values put here will NOT be inherited by subclasses
sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         attribute1 => $self->global->attribute,
         attribute2 => [ qw(val1 val2) ],
      },
   };
}

sub brik_preinit {
}

sub brik_init {
   my $self = shift;

   # Do your init here, return 0 on error.

   return $self->SUPER::brik_init;
}

sub command1 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      return $self->log->error($self->brik_help_run('command1'));
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub command2 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      return $self->log->error($self->brik_help_run('command2'));
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub brik_fini {
}

1;

__END__

=head1 NAME

Metabrik::Example::Template - example::template Brik

=head1 SYNOPSIS

   # Prepare a skeleton in order to create a new Brik

   $ cp lib/Metabrik/Example/Template.pm ~/myMetabriky/lib/Category/Mybrik.pm
   $ vi ~/myMetabrik/lib/Category/Mybrik.pm

   # Use a Brik from a Perl module

   use Metabrik::Example::Template;

   my $value1 = 'value1';

   my $brik = Metabrik::Example::Template->new;
   $brik->brik_init;
   $brik->attribute1($value);
   $brik->attribute2(1);

   my $result = $brik->command1($argument1, $argument2);

   # Use a Brik from a the Metabrik Shell

   > my $value1 = 'value1'
   > set example::template attribute1 $value1
   > set example::template attribute2 1
   > run example::template command1 argument1 argument2
   > $RUN  # Will contain the result

   # Use a Brik from the Metabrik Shell (Perl multiline code)

   > for my $this (1..3) { \
   ..    $CON->run('example::template', 'command1', 'argument1', $this); \
   .. }

   # Another option
   > for my $this (1..3) { \
   ..    $SHE->cmd('run example::template command1 argument1 $this'); \
   .. }

   # Use a Brik from a Metabrik Brik

   my $context = $self->context;

   my $value1 = 'value1';

   $context->use('example::template');
   $context->set('example::template', 'attribute1', $value1);
   $context->set('example::template', 'attribute2', 1);

   my $result = $context->run('example::template', 'command1', 'argument1', 'argument2');

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
