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
         save => [ qw($csv_struct output|OPTIONAL) ],
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

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('country_code_types'));
   }

   my %list = ();
   for my $this (@$data) {
      $list{$data->{$this}->{type}}++;
   }

   my @types = sort { $a cmp $b } keys %list;

   return \@types;
}

# Port numbers:
# http://www.iana.org/protocols
# http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml

sub update {
   my $self = shift;

   my $uri = 'http://www.iana.org/domains/root/db';

   my $get = $self->get($uri) or return $self->log->error("update: get failed");
   my $html = $get->{content};

   # <tr class="iana-group-1 iana-type-2">
   #   <td><span class="domain tld"><a href="/domains/root/db/abogado.html">.abogado</a></span></td>
   #   <td>generic</td>
   #   <!-- <td>-<br/><span class="tld-table-so">Top Level Domain Holdings Limited</span></td> </td> -->
   #   <td>Top Level Domain Holdings Limited</td>
   # </tr>

   my @cc = ();
   while ($html =~ m{<tr class="iana-group-\d+\s+iana-type-\d+">(.*?)</tr>}gcs) {
      my $this = $1;

      $this =~ s/\n//g;

      $self->debug && $self->log->debug("update: this[$this]");

      #my ($tld, $type, $country, $sponsor) = ($this =~ m{^.*?<a href.*?>(.*?)<.*?<td>(.*?)<.*?<td>(.*?)<.*>(.*?)</span>.*$});
      my ($tld, $type, $country, $sponsor) = ($this =~ m{^.*?<a href.*?>(.*?)<.*?<td>(.*?)<.*?<td>(.*?)<.*<span.*?>(.*?)</span>.*$});

      #print "tld[$tld]\n";
      #print "type[$type]\n";
      #print "sponsor[$sponsor]\n";

      push @cc, {
         tld => $tld,
         country => $country,
         type => $type,
         sponsor => $sponsor,
      };
   }

   return \@cc;
}

sub save {
   my $self = shift;
   my ($data, $output) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('save'));
   }

   $output ||= $self->output;

   my $datadir = $self->datadir;

   my $file_csv = Metabrik::File::Csv->new_from_brik($self) or return;
   $file_csv->overwrite(1);
   $file_csv->encoding('utf8');

   my $output_file = $datadir.'/'.$output;
   $file_csv->write($data, $output_file)
      or return $self->log->error("save: write failed");

   return $output_file;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! -f $input) {
      return $self->log->error("load: file [$input] not found");
   }

   my $datadir = $self->datadir;

   my $file_csv = Metabrik::File::Csv->new_from_brik($self) or return;
   $file_csv->first_line_is_header(1);

   my $csv = $file_csv->read($datadir.'/'.$input);

   return $csv;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Countrycode - lookup::countrycode Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
