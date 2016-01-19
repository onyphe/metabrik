#
# $Id$
#
# lookup::countrycode Brik
#
package Metabrik::Lookup::Countrycode;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable iana cc) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
      },
      attributes_default => {
         input => 'country-codes.csv',
         output => 'country-codes.csv',
      },
      commands => {
         update => [ ],
         load => [ qw(input|OPTIONAL) ],
         country_code_types => [ qw($csv_struct) ],
      },
      require_modules => {
         'Metabrik::File::Csv' => [ ],
      },
   };
}

sub country_code_types {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('country_code_types', $data) or return;

   my %list = ();
   for my $this (@$data) {
      $list{$data->{$this}->{type}}++;
   }

   my @types = sort { $a cmp $b } keys %list;

   return \@types;
}

#
# Port numbers:
# http://www.iana.org/protocols
# http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
#
sub update {
   my $self = shift;
   my ($output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('update', $output) or return;

   my $datadir = $self->datadir;

   my $uri = 'http://www.iana.org/domains/root/db';

   my $get = $self->get($uri) or return;
   my $html = $get->{content};

   # <tr class="iana-group-1 iana-type-2">
   #   <td><span class="domain tld"><a href="/domains/root/db/abogado.html">.abogado</a></span></td>
   #   <td>generic</td>
   #   <!-- <td>-<br/><span class="tld-table-so">Top Level Domain Holdings Limited</span></td> </td> -->
   #   <td>Top Level Domain Holdings Limited</td>
   # </tr>

   my @cc = ();
   while ($html =~ m{<span class="domain tld">(.*?)</tr>}gcs) {
      my $this = $1;

      $this =~ s/\n//g;

      $self->debug && $self->log->debug("update: this[$this]");

      my ($tld, $type, $country, $sponsor) = ($this =~ m{^.*?<a href.*?>(.*?)<.*?<td>(.*?)<.*?<td>(.*?)<.*$});

      push @cc, {
         tld => $tld,
         country => $country,
         type => $type,
         sponsor => $sponsor,
      };
   }

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->append(0);
   $fc->overwrite(1);
   $fc->encoding('utf8');

   my $output_file = $datadir.'/'.$output;
   $fc->write(\@cc, $output_file) or return;

   return $output_file;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('load', $input) or return;
   $self->brik_help_run_file_not_found('load', $input) or return;

   my $datadir = $self->datadir;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->first_line_is_header(1);

   my $csv = $fc->read($datadir.'/'.$input) or return;

   return $csv;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Countrycode - lookup::countrycode Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
