#
# $Id$
#
# file::zip brik
#
package Metabrik::File::Compress;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable gzip unzip gunzip uncompress) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(directory) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
      },
      attributes_default => {
         datadir => '.', # Uncompress in current directory by default
      },
      commands => {
         install => [ ], # Inherited
         unzip => [ qw(input|OPTIONAL datadir|OPTIONAL) ],
         gunzip => [ qw(input|OPTIONAL output|OPTIONAL datadir|OPTIONAL) ],
         uncompress => [ qw(input|OPTIONAL output|OPTIONAL datadir|OPTIONAL) ],
      },
      require_modules => {
         'Compress::Zlib' => [ ],
         'Metabrik::File::Type' => [ ],
         'Metabrik::File::Write' => [ ],
      },
      require_binaries => {
         'unzip' => [ ],
      },
      need_packages => {
         'ubuntu' => [ qw(unzip) ],
      },
   };
}

sub unzip {
   my $self = shift;
   my ($input, $datadir) = @_;

   $input ||= $self->input;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('unzip', $input) or return;

   my $cmd = "unzip -o $input -d $datadir/";

   $self->system($cmd) or return;

   return $datadir;
}

sub gunzip {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   $output ||= $self->output;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('gunzip', $input) or return;

   # If no output given, we use the input file name by removing .gz like gunzip command
   if (! defined($output)) {
      ($output = $input) =~ s/.gz$//;
   }

   my $gz = Compress::Zlib::gzopen($input, "rb");
   if (! $gz) {
      return $self->log->error("gunzip: gzopen file [$input]: [$Compress::Zlib::gzerrno]");
   }

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->append(0);
   $fw->encoding('ascii');
   $fw->overwrite(1);

   my $fd = $fw->open($datadir.'/'.$output) or return;

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

   if (! $no_error) {
      $self->log->warning("gunzip: had some errors during gunzipping");
   }

   $fw->close;

   return $output;
}

sub uncompress {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('uncompress', $input) or return;

   my $ft = Metabrik::File::Type->new_from_brik_init($self) or return;
   my $type = $ft->get_mime_type($input) or return;

   if ($type eq 'application/gzip') {
      return $self->gunzip($input, $output, $datadir);
   }
   elsif ($type eq 'application/zip'
   ||     $type eq 'application/vnd.oasis.opendocument.text'
   ||     $type eq 'application/java-archive') {
      return $self->unzip($input, $datadir);
   }

   return $self->log->error("uncompress: don't know how to uncompress file [$input] with MIME type [$type]");
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
