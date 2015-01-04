#
# $Id$
#
# iana::countrycode Brik
#
package Metabrik::Iana::Countrycode;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable iana countrycode cc) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
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

sub brik_use_properties {
   my $self = shift;

   my $dir = $self->global->datadir.'/iana-countrycode';
   if (! -d $dir) {
      mkdir($dir)
         or return $self->log->error("brik_use_properties: mkdir failed for dir [$dir]");
   }

   return {
      attributes_default => {
         input => $dir.'/country-codes.csv',
         output => $dir.'/country-codes.csv',
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
   my $html = $get->{body};

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
   if (! defined($output)) {
      return $self->log->error($self->brik_help_run('save'));
   }

   my $file_csv = Metabrik::File::Csv->new_from_brik($self);
   $file_csv->overwrite(1);
   $file_csv->encoding('utf8');

   $file_csv->write($data, $output)
      or return $self->log->error("save: write failed");

   return $output;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_set('input'));
   }
   if (! -f $input) {
      return $self->log->error("load: file [$input] not found");
   }

   my $file_csv = Metabrik::File::Csv->new_from_brik($self);
   $file_csv->first_line_is_header(1);

   my $csv = $file_csv->read($input);

   return $csv;
}

1;

__END__

=head1 NAME

Metabrik::Iana::Countrycode - iana::countrycode Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
