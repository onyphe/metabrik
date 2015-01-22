#
# $Id$
#
# lookup::protocol Brik
#
package Metabrik::Lookup::Protocol;
use strict;
use warnings;

use base qw(Metabrik::File::Csv);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable lookup protocol iana) ],
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(input) ],
      },
      attributes_default => {
         separator => ',',
         input => 'protocol-numbers-1.csv',
      },
      commands => {
         update => [ qw(output|OPTIONAL) ],
         load => [ qw(input|OPTIONAL) ],
         int => [ qw(int_number) ],
         hex => [ qw(hex_number) ],
         string => [ qw(ip_type) ],
      },
      require_modules => {
         'Metabrik::File::Fetch' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub update {
   my $self = shift;
   my ($output) = @_;

   my $url = 'http://www.iana.org/assignments/protocol-numbers/protocol-numbers-1.csv';
   my ($file) = $self->input;

   $output ||= $self->datadir.'/'.$file;

   my $ff = Metabrik::File::Fetch->new_from_brik($self) or return;
   $ff->get($url, $output)
      or return $self->log->error("update: get failed");

   # We have to rewrite the CSV file, cause some entries are multiline.
   my $ft = Metabrik::File::Text->new_from_brik($self) or return;
   $ft->overwrite(1);
   $ft->append(0);
   my $text = $ft->read($file)
      or return $self->log->error("update: read failed");

   my @new = split(/\r\n/, $text);
   for (@new) {
      s/\n/ /g;
   }

   $ft->write(\@new, $output);

   return $output;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->datadir.'/'.$self->input;
   if (! -f $input) {
      return $self->log->error($self->brik_help_set('input'));
   }

   my $data = $self->read($input);

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Protocol - lookup::protocol Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
