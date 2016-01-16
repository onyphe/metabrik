#
# $Id$
#
# shell::command Brik
#
package Metabrik::Shell::Command;
use strict;
use warnings;

our $VERSION = '1.20';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(exec execute) ],
      attributes => {
         as_array => [ qw(0|1) ],
         as_matrix => [ qw(0|1) ],
         capture_stderr => [ qw(0|1) ],
         capture_mode => [ qw(0|1) ],
         ignore_error => [ qw(0|1) ],
         use_sudo => [ qw(0|1) ],
         use_pager => [ qw(0|1) ],
         use_globbing => [ qw(0|1) ],
         sudo_args => [ qw(args) ],
      },
      attributes_default => {
         as_array => 1,
         as_matrix => 0,
         capture_stderr => 1,
         capture_mode => 0,
         ignore_error => 1,
         use_sudo => 0,
         use_pager => 0,
         use_globbing => 1,
         sudo_args => '-E',  # Keep environment
      },
      commands => {
         system => [ qw(command) ],
         sudo_system => [ qw(command) ],
         capture => [ qw(command) ],
         sudo_capture => [ qw(command) ],
         execute => [ qw(command) ],
         sudo_execute => [ qw(command) ],
      },
      require_modules => {
         'IPC::Run3' => [ ],
      },
   };
}

sub system {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('system', $cmd) or return;

   # Remove undefined values from arguments
   my @new;
   for (@args) {
      if (defined($_)) {
         push @new, $_;
      }
   }

   my $command = join(' ', $cmd, @new);
   my @toks = split(/\s+/, $command);
   my $bin = $toks[0];

   my @path = split(':', $ENV{PATH});
   if (! -f $bin) {  # If file is not directly found
      for my $path (@path) {
         if (-f "$path/$bin") {
            $bin = "$path/$bin";
            last;
         }
      }
   }
   $toks[0] = $bin;

   if (! -f $bin) {
      return $self->log->error("system: program [$bin] not found in PATH");
   }

   $command = join(' ', @toks);

   if ($self->use_sudo) {
      my @sudo = ( "sudo" );
      if (! ref($self->sudo_args) && length($self->sudo_args)) {
         my @args = split(/\s+/, $self->sudo_args);
         push @sudo, @args;
      }
      $command = join(' ', @sudo)." $command";
      @toks = ( @sudo, @toks );
      $self->log->verbose("system: using sudo: running [$command]");
   }

   if ($self->use_pager) {
      my $pager = $ENV{PAGER} || 'less';
      $command .= " | $pager";
   }

   my $r = CORE::system($command);

   $self->debug && $self->log->debug("system: return code [$r] with status [$?]");

   if (! $self->ignore_error && $? != 0) {
      $self->log->verbose("system: exit code[$?]");
      # Failure, we return the program exit code
      return $?;
   }

   # Success
   if ($r == 0) {
      return 1;
   }

   return 1;
}

sub sudo_system {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_system', $cmd) or return;

   my $prev = $self->use_sudo;
   $self->use_sudo(1);
   my $r = $self->system($cmd, @args);
   $self->use_sudo($prev);

   return $r;
}

sub capture {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('capture', $cmd) or return;

   # Remove undefined values from arguments
   my @new;
   for (@args) {
      if (defined($_)) {
         push @new, $_;
      }
   }

   my $command = join(' ', $cmd, @new);
   my @toks = split(/\s+/, $command);
   my $bin = $toks[0];

   my @path = split(':', $ENV{PATH});
   if (! -f $bin) {  # If file is not directly found
      for my $path (@path) {
         if (-f "$path/$bin") {
            $bin = "$path/$bin";
            last;
         }
      }
   }
   $toks[0] = $bin;

   if (! -f $bin) {
      return $self->log->error("capture: program [$bin] not found in PATH");
   }

   # Perform file globbing, if any
   if ($self->use_globbing) {
      my @globbed = ();
      for (@toks) {
         push @globbed, glob($_);
      }
      @toks = @globbed;
   }

   $command = join(' ', @toks);

   if ($self->use_sudo) {
      my @sudo = ( "sudo" );
      if (! ref($self->sudo_args) && length($self->sudo_args)) {
         my @args = split(/\s+/, $self->sudo_args);
         push @sudo, @args;
      }
      $command = join(' ', @sudo)." $command";
      @toks = ( @sudo, @toks );
      $self->log->verbose("capture: using sudo: running [$command]");
   }

   my $out;
   my $err;
   eval {
      my $cmd = join(' ', @toks);
      IPC::Run3::run3($cmd, undef, \$out, \$err);
   };
   # Error in executing run3()
   if ($@) {
      chomp($@);
      return $self->log->error("capture: unable to execute command [$command]: $@");
   }
   # Error in command execution
   elsif ($?) {
      chomp($err);
      chomp($out);
      $err ||= $out; # Sometimes, the error is printed on stdout instead of stderr
      if ($self->ignore_error) {
         $self->log->warning("capture: command execution had errors [$command]: $err");
      }
      else {
         return $self->log->error("capture: command execution failed [$command]: $err");
      }
   }

   $out ||= 'undef';
   $err ||= 'undef';
   chomp($out);
   chomp($err);

   # If we also wanted stderr, we put it at the end of output
   if ($self->capture_stderr && $err ne 'undef') {
      $out .= "\n\nSTDERR:\n$err";
   }

   # as_matrix has precedence over as_array (because as_array is the default)
   if (! $self->as_matrix && $self->as_array) {
      $out = [ split(/\n/, $out) ];
   }
   elsif ($self->as_matrix) {
      my @matrix = ();
      for my $this (split(/\n/, $out)) {
         push @matrix, [ split(/\s+/, $this) ];
      }
      $out = \@matrix;
   }

   return $out;
}

sub sudo_capture {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_capture', $cmd) or return;

   my $prev = $self->use_sudo;
   $self->use_sudo(1);
   my $r = $self->capture($cmd, @args);
   $self->use_sudo($prev);

   return $r;
}

sub execute {
   my $self = shift;
   my ($cmd, @args) = @_;
   
   $self->brik_help_run_undef_arg('execute', $cmd) or return;

   if ($self->capture_mode) {
      return $self->capture($cmd, @args);
   }
   else {  # non-capture mode
      return $self->system($cmd, @args);
   }

   # Unknown error
   return;
}

sub sudo_execute {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_execute', $cmd) or return;

   if ($self->capture_mode) {
      return $self->sudo_capture($cmd, @args);
   }
   else {  # non-capture mode
      return $self->sudo_system($cmd, @args);
   }

   # Unknown error
   return;
}

1;

__END__

=head1 NAME

Metabrik::Shell::Command - shell::command Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
