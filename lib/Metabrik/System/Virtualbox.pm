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
         dumpguestcore => [ qw(name file.elf) ],
         dumpvmcore => [ qw(name file.elf) ],
         extract_memdump_from_dumpguestcore => [ qw(input output) ],
         restart => [ qw(name type|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Raw' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Readelf' => [ ],
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

#
# Dump guestcore
#
sub dumpguestcore {
   my $self = shift;
   my ($name, $file) = @_;

   $self->brik_help_run_undef_arg('dumpguestcore', $name) or return;
   $self->brik_help_run_undef_arg('dumpguestcore', $file) or return;

   $self->command("debugvm \"$name\" dumpguestcore --filename \"$file\"") or return;

   return $file;
}

#
# Dump vmcore, same as dump guestcore but for newer versions of VirtualBox which renamed 
# the function
#
sub dumpvmcore {
   my $self = shift;
   my ($name, $file) = @_;

   $self->brik_help_run_undef_arg('dumpvmcore', $name) or return;
   $self->brik_help_run_undef_arg('dumpvmcore', $file) or return;

   $self->command("debugvm \"$name\" dumpvmcore --filename \"$file\"") or return;

   return $file;
}

#
# By taking information from:
# http://wiki.yobi.be/wiki/RAM_analysis#RAM_dump_with_VirtualBox:_via_ELF64_coredump
#
sub extract_memdump_from_dumpguestcore {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('extract_memdump_from_dumpguestcore', $input) or return;
   $self->brik_help_run_undef_arg('extract_memdump_from_dumpguestcore', $output) or return;

   my $fraw = Metabrik::File::Raw->new_from_brik_init($self) or return;
   my $fread = Metabrik::File::Read->new_from_brik_init($self) or return;
   my $felf = Metabrik::File::Readelf->new_from_brik_init($self) or return;

   my $headers = $felf->program_headers($input) or return;

   my $offset = 0;
   my $size = 0;
   for my $section (@{$headers->{sections}}) {
      if ($section->{type} eq 'LOAD') {
         $offset = hex($section->{offset});
         $size = hex($section->{filesiz});
         last;
      }
   }
   if (! $offset || ! $size) {
      return $self->log->error("extract_memdump_from_dumpguestcore: unable to find memdump");
   }

   $self->log->verbose("extract_memdump_from_dumpguestcore: offset[$offset] size[$size]");

   $fread->encoding('ascii');  # Raw mode
   my $fdin = $fread->open($input) or return;
   $fread->seek($offset) or return;

   my $written = 0;
   my $fdout = $fraw->open($output) or return;
   while (<$fdin>) {
      my $this = length($_);
      if (($written + $this) <= $size) {
         print $fdout $_;
         $written += $this;
      }
      else {
         my $rest = $size - $written;
         if ($rest < 0) {
            $self->log->warning("extract_memdump_from_dumpguestcore: error while reading input");
            last;
         }
         my $tail = substr($_, 0, $rest);
         print $fdout $tail;
         last;
      }
   }
   $fraw->close;
   $fread->close;

   return $output;
}

sub restart {
   my $self = shift;
   my ($name, $type) = @_;

   $self->brik_help_run_undef_arg('restart', $name) or return;

   $self->stop($name) or return;
   sleep(2);
   return $self->start($name, $type);
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
