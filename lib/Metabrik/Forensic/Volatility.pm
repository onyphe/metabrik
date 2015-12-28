#
# $Id$
#
# forensic::Volatility Brik
#
package Metabrik::Forensic::Volatility;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable carving carve file filecarve filecarving) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         profile => [ qw(profile) ],
         input => [ qw(file) ],
         capture_mode => [ qw(0|1) ],
      },
      attributes_default => {
         profile => 'Win7SP1x64',
         capture_mode => 1,
      },
      commands => {
         imageinfo => [ qw(file|OPTIONAL) ],
         command => [ qw(command file|OPTIONAL profile|OPTIONAL) ],
         envars => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         pstree => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         netscan => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         hashdump => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         psxview => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         hivelist => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         hivedump => [ qw(offset file|OPTIONAL profile|OPTIONAL) ],
         filescan => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         consoles => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         memdump => [ qw(pid file|OPTIONAL profile|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'volatility' => [ ],
      },
   };
}

sub imageinfo {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->input;
   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('imageinfo', $file) or return;
   $self->brik_help_run_file_not_found('imageinfo', $file) or return;

   my $cmd = "volatility imageinfo -f $file";

   $self->log->info("imageinfo: running...");
   my $data = $self->capture($cmd);
   $self->log->info("imageinfo: running...done");

   my @profiles = ();
   for my $line (@$data) {
      if ($line =~ m{suggested profile}i) {
         my @toks = split(/\s+/, $line);
         @profiles = @toks[4..$#toks];
         for (@profiles) {
            s/,$//g;
         }
      }
   }

   return \@profiles;
}

sub command {
   my $self = shift;
   my ($command, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('command', $command) or return;
   $self->brik_help_run_undef_arg('command', $file) or return;
   $self->brik_help_run_undef_arg('command', $profile) or return;

   my $cmd = "volatility --profile $profile $command -f $file";

   return $self->execute($cmd);
}

sub envars {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('envars', $file) or return;
   $self->brik_help_run_undef_arg('envars', $profile) or return;

   my $cmd = "volatility --profile $profile envars -f $file";

   return $self->execute($cmd);
}

sub pstree {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('pstree', $file) or return;
   $self->brik_help_run_undef_arg('pstree', $profile) or return;

   my $cmd = "volatility --profile $profile pstree -v -f $file";

   return $self->execute($cmd);
}

sub netscan {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('netscan', $file) or return;
   $self->brik_help_run_undef_arg('netscan', $profile) or return;

   my $cmd = "volatility --profile $profile netscan -v -f $file";

   return $self->execute($cmd);
}

sub memdump {
   my $self = shift;
   my ($pid, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('memdump', $pid) or return;
   $self->brik_help_run_undef_arg('memdump', $file) or return;
   $self->brik_help_run_undef_arg('memdump', $profile) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($pid) or return;

   my $cmd = "volatility --profile $profile memdump -p $pid --dump-dir $pid/ -f $file";
   $self->execute($cmd) or return;

   return "$pid/$pid.dmp";
}

sub hashdump {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('hashdump', $file) or return;
   $self->brik_help_run_undef_arg('hashdump', $profile) or return;

   my $cmd = "volatility --profile $profile hashdump -f $file";

   return $self->execute($cmd);
}

sub psxview {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('psxview', $file) or return;
   $self->brik_help_run_undef_arg('psxview', $profile) or return;

   my $cmd = "volatility --profile $profile psxview -f $file";

   return $self->execute($cmd);
}

sub hivelist {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('hivelist', $file) or return;
   $self->brik_help_run_undef_arg('hivelist', $profile) or return;

   my $cmd = "volatility --profile $profile hivelist -f $file";

   return $self->execute($cmd);
}

sub hivedump {
   my $self = shift;
   my ($offset, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('hivedump', $offset) or return;
   $self->brik_help_run_undef_arg('hivedump', $file) or return;
   $self->brik_help_run_undef_arg('hivedump', $profile) or return;

   my $cmd = "volatility --profile $profile hivedump --hive-offset $offset -f $file";

   return $self->execute($cmd);
}

sub filescan {
   my $self = shift;
   my ($offset, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('filescan', $offset) or return;
   $self->brik_help_run_undef_arg('filescan', $file) or return;
   $self->brik_help_run_undef_arg('filescan', $profile) or return;

   my $cmd = "volatility --profile $profile filescan -f $file";

   return $self->execute($cmd);
}

sub consoles {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('consoles', $file) or return;
   $self->brik_help_run_undef_arg('consoles', $profile) or return;

   my $cmd = "volatility --profile $profile consoles -f $file";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Forensic::Volatility - forensic::volatility Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
