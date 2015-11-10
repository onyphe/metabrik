#
# $Id$
#
# log::null Brik
#
package Metabrik::Log::Null;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(log null) ],
      attributes => {
         level => [ qw(0|1|2|3) ],
      },
      commands => {
         info => [ qw(string caller|OPTIONAL) ],
         verbose => [ qw(string caller|OPTIONAL) ],
         warning => [ qw(string caller|OPTIONAL) ],
         error => [ qw(string caller|OPTIONAL) ],
         fatal => [ qw(string caller|OPTIONAL) ],
         debug => [ qw(string caller|OPTIONAL) ],
      },
   };
}

sub brik_preinit {
   my $self = shift;

   my $context = $self->context;

   # We replace the current logging Brik by this one.
   $context->{log} = $self;
   for my $this (keys %{$context->used}) {
      $context->{used}->{$this}->{log} = $self;
   }

   # We have to init this new log Brik, because previous one
   # was already inited at this stage. We have to keep the same init context.
   $self->brik_init or return $self->log->error("brik_preinit: init error");

   return $self;
}

sub _msg {
   my $self = shift;
   my ($brik, $msg) = @_;

   $msg ||= 'undef';

   $brik =~ s/^metabrik:://i;

   return lc($brik).": $msg\n";
}

sub warning {
   my $self = shift;

   return 1;
}

sub error {
   my $self = shift;

   return;
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $buffer = "[F] ".$self->_msg(($caller) ||= caller(), $msg);

   die($buffer);
}

sub info {
   my $self = shift;

   return 1;
}

sub verbose {
   my $self = shift;

   return 1;
}

sub debug {
   my $self = shift;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Log::Null - log::null Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
