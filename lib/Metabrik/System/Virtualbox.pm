#
# $Id$
#
# system::virtualbox Brik
#
package Metabrik::System::Virtualbox;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         capture_mode => [ qw(0|1) ],
         type => [ qw(gui|sdl|headless) ],
      },
      attributes_default => {
         capture_mode => 1,
         type => 'gui',
      },
      commands => {
         install => [ ], # Inherited
         command => [ qw(command) ],
         list => [ ],
         start => [ qw(name type|OPTIONAL) ],
         restore => [ qw(name type|OPTIONAL) ], # Alias for start
         stop => [ qw(name) ],
         save => [ qw(name) ],
         snapshot_list => [ qw(name) ],
         snapshot_live => [ qw(name snapshot_name description|OPTIONAL) ],
         snapshot_delete => [ qw(name snapshot_name) ],
         snapshot_restore => [ qw(name snapshot_name) ],
         screenshot => [ qw(name file.png) ],
      },
      require_binaries => {
         vboxmanage => [ ],
      },
      need_packages => {
         ubuntu => [ qw(virtualbox) ],
      },
   };
}

sub command {
   my $self = shift;
   my ($command) = @_;

   $self->brik_help_run_undef_arg('command', $command) or return;

   return $self->execute("vboxmanage $command");
}

sub list {
   my $self = shift;

   my %vms = ();
   my $lines = $self->command('list vms') or return;
   for my $line (@$lines) {
      my ($name, $uuid) = $line =~ m/^\s*"([^"]+)"\s+{([^}]+)}\s*$/;
      $vms{$uuid} = { uuid => $uuid, name => $name };
   }

   return \%vms;
}

sub start {
   my $self = shift;
   my ($name, $type) = @_;

   $type ||= $self->type;
   $self->brik_help_run_undef_arg('start', $name) or return;
   $self->brik_help_run_undef_arg('start', $type) or return;

   return $self->command("startvm \"$name\" --type $type");
}

sub restore {
   my $self = shift;

   return $self->start(@_);
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('stop', $name) or return;

   return $self->command("controlvm \"$name\" poweroff");
}

sub save {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('save', $name) or return;

   return $self->command("controlvm \"$name\" savestate");
}

sub snapshot_list {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('snapshot_list', $name) or return;

   return $self->command("snapshot \"$name\" list");
}

sub snapshot_live {
   my $self = shift;
   my ($name, $snapshot_name, $description) = @_;

   $description ||= 'snapshot';
   $self->brik_help_run_undef_arg('snapshot_live', $name) or return;
   $self->brik_help_run_undef_arg('snapshot_live', $snapshot_name) or return;

   return $self->command("snapshot \"$name\" take \"$snapshot_name\" --description \"$description\" --live");
}

sub snapshot_delete {
   my $self = shift;
   my ($name, $snapshot_name) = @_;

   $self->brik_help_run_undef_arg('snapshot_delete', $name) or return;
   $self->brik_help_run_undef_arg('snapshot_delete', $snapshot_name) or return;

   return $self->command("snapshot \"$name\" delete \"$snapshot_name\"");
}

sub snapshot_restore {
   my $self = shift;
   my ($name, $snapshot_name) = @_;

   $self->brik_help_run_undef_arg('snapshot_restore', $name) or return;
   $self->brik_help_run_undef_arg('snapshot_restore', $snapshot_name) or return;

   return $self->command("snapshot \"$name\" restore \"$snapshot_name\"");
}

sub screenshot {
   my $self = shift;
   my ($name, $file) = @_;

   $self->brik_help_run_undef_arg('screenshot', $name) or return;
   $self->brik_help_run_undef_arg('screenshot', $file) or return;

   $self->command("controlvm \"$name\" screenshotpng \"$file\"") or return;

   return $file;
}

1;

__END__

=head1 NAME

Metabrik::System::Virtualbox - system::virtualbox Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
