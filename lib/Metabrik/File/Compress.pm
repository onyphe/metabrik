#
# $Id$
#
# file::zip brik
#
package Metabrik::File::Compress;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable compress unzip gunzip uncompress) ],
      attributes => {
         datadir => [ qw(directory) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
      },
      commands => {
         unzip => [ qw(input|OPTIONAL datadir|OPTIONAL) ],
         gunzip => [ qw(input|OPTIONAL output|OPTIONAL datadir|OPTIONAL) ],
         uncompress => [ qw(input|OPTIONAL output|OPTIONAL datadir|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Write' => [ ],
         'Compress::Zlib' => [ ],
      },
      require_binaries => {
         'unzip' => [ ],
      },
   };
}

sub unzip {
   my $self = shift;
   my ($input, $datadir) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('unzip'));
   }

   $datadir ||= $self->datadir;

   my $cmd = "unzip -o $input -d $datadir/";

   $self->system($cmd) or return;

   return $datadir;
}

sub gunzip {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('gunzip'));
   }

   $output ||= $self->output;
   # If no output given, we used the input file name by removing .gz like gunzip command
   if (! defined($output)) {
      ($output = $input) =~ s/.gz$//;
   }

   $datadir ||= $self->datadir;

   my $gz = Compress::Zlib::gzopen($input, "rb");
   if (! $gz) {
      return $self->log->error("gunzip: gzopen file [$input]: [$Compress::Zlib::gzerrno]");
   }

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->append(0);
   $fw->encoding('ascii');
   $fw->overwrite(1);

   my $fd = $fw->open($datadir.'/'.$output);
   if (! defined($fd)) {
      return $self->log->error("gunzip: open failed");
   }

   my $no_error = 1;
   my $buffer = '';
   while ($gz->gzread($buffer) > 0) {
      $self->debug && $self->log->debug("gunzip: gzread ".length($buffer));
      my $r = $fw->write($buffer);
      $buffer = '';
      if (! defined($r)) {
         $self->log->warning("gunzip: write failed");
         $no_error = 0;
         next;
      }
   }

   $fw->close;

   return $no_error;
}

sub uncompress {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('uncompress'));
   }

   $datadir ||= $self->datadir;

   if ($input =~ /\.gz$/) {
      return $self->gunzip($input, $output, $datadir);
   }
   elsif ($input =~ /\.zip$/) {
      return $self->unzip($input, $datadir);
   }

   return $self->log->error("uncompress: don't know how to uncompress file [$input]");
}

1;

__END__

=head1 NAME

Metabrik::File::Compress - file::compress Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
