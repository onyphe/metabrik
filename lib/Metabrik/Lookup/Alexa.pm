#
# $Id$
#
# lookup::alexa Brik
#
package Metabrik::Lookup::Alexa;
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
         datadir => [ qw(datadir) ],
         url => [ qw(url) ],
         input => [ qw(file) ],
      },
      attributes_default => {
         url => 'http://s3.amazonaws.com/alexa-static/top-1m.csv.zip',
         input => 'top-1m.csv',  # Stored in datadir by default
      },
      commands => {
         install => [ ],  # Inherited
         update => [ ],
         load => [ qw(input|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
         'Metabrik::File::Csv' => [ ],
         'Metabrik::System::File' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;
   my $url = $self->url;
   my $outfile_zip = $datadir.'/alexa-top1m.csv.zip';
   my $outfile_csv = $datadir.'/alexa-top1m.csv';

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;

   my $files = $cw->mirror($url, $outfile_zip) or return;

   my @updated = ();
   if (@$files > 0) {  # Update was available
      my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
      for my $file (@$files) {
         my $uncompressed = $fc->uncompress($file, $outfile_csv, $datadir) or next;
         push @updated, @$uncompressed;
      }
   }

   return \@updated;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   # If not provided, we use the default from datadir
   if (! defined($input)) {
      $input = $self->datadir.'/'.$self->input;
   }

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->separator(',');
   $fc->first_line_is_header(0);

   my $data = $fc->read($input) or return;

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Alexa - lookup::alexa Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
