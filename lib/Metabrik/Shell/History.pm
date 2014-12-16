#
# $Id$
#
# shell::history Brik
#
package Metabrik::Shell::History;
use strict;
use warnings;

our $VERSION = '1.03';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell history) ],
      attributes => {
         history_file => [ qw(file) ],
      },
      commands => {
         load => [ ],
         write => [ ],
         get => [ ],
         get_one => [ qw(integer) ],
         get_range => [ qw(integer_first..integer_last) ],
         show => [ ],
         exec => [ qw(integer|integer_first..integer_last) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         history_file => $self->global->homedir.'/.metabrik_history',
      },
   };
}

sub load {
   my $self = shift;

   my $shell = $self->shell;
   my $history_file = $self->history_file;

   if ($shell->term->can('ReadHistory')) {
      if (! -f $history_file) {
         return $self->log->error("load: can't find history file [$history_file]");
      }

      $shell->term->ReadHistory($history_file)
         or return $self->log->error("load: can't ReadHistory file [$history_file]: $!");

      $self->debug && $self->log->debug("load: success");
   }
   else {
      $self->log->warning("load: cannot ReadHistory");
   }

   return 1;
}

sub write {
   my $self = shift;

   my $shell = $self->shell;
   my $history_file = $self->history_file;

   if ($shell->term->can('WriteHistory')) {
      $shell->term->WriteHistory($history_file)
         or return $self->log->error("load: can't WriteHistory file [$history_file]: $!");
      $self->debug && $self->log->debug("write: success");
   }
   else {
      $self->log->warning("load: cannot WriteHistory");
   }

   return 1;
}

sub get {
   my $self = shift;

   my $shell = $self->shell;

   my @history = ();
   if ($shell->term->can('GetHistory')) {
      @history = $shell->term->GetHistory;

      $self->debug && $self->log->debug("get: success");
   }
   else {
      $self->log->warning("load: cannot GetHistory");
   }

   return \@history;
}

sub get_one {
   my $self = shift;
   my ($number) = @_;

   if (! defined($number) || $number !~ /^\d+$/) {
      return $self->log->error($self->brik_help_run('get_one'));
   }

   my $shell = $self->shell;

   my $history = '';
   my @history = ();
   if ($shell->term->can('GetHistory')) {
      @history = $shell->term->GetHistory;
      $history = $history[$number];

      $self->debug && $self->log->debug("get_one: success");
   }
   else {
      $self->log->warning("load: cannot GetHistory");
   }

   return $history;
}

sub get_range {
   my $self = shift;
   my ($range) = @_;

   if (! defined($range) || $range !~ /^\d+\.\.\d+$/) {
      return $self->log->error($self->brik_help_run('get_range'));
   }

   my $shell = $self->shell;

   my @history = ();
   if ($shell->term->can('GetHistory')) {
      @history = $shell->term->GetHistory;
      @history = @history[eval($range)];

      $self->debug && $self->log->debug("get_range: success");
   }
   else {
      $self->log->warning("load: cannot GetHistory");
   }

   return \@history;
}

sub show {
   my $self = shift;

   my $history = $self->get;

   my $count = 0;
   for (@$history) {
      $self->log->info("[".$count++."] $_");
   }

   return $count - 1;
}

sub exec {
   my $self = shift;
   my ($numbers) = @_;

   my $context = $self->context;

   if (! defined($numbers)) {
      return $self->log->error($self->brik_help_run('exec'));
   }

   # We want to exec some history command(s)
   my $lines = [];
   if ($numbers =~ /^\d+$/) {
      $lines = [ $self->get_one($numbers) ];
   }
   elsif ($numbers =~ /^\d+\.\.\d+$/) {
      $lines = $self->get_range($numbers);
   }

   for (@$lines) {
      if (/^exit$/) {
         exit(0);
      }
      $context->run('core::shell', 'cmd', $_);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Shell::History - shell::history Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
