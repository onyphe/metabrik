#
# $Id$
#
# iana::countrycode Brik
#
package Metabrik::Iana::Countrycode;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable iana countrycode cc) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         _data => [ ],
      },
      commands => {
         country_code_types => [ ],
         update => [ ],
         save => [ ],
         load => [ ],
      },
      require_used => {
         'www::client' => [ ],
         'file::csv' => [ ],
         'file::write' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->datadir."/iana-country-codes.csv",
         output => $self->global->datadir."/iana-country-codes.csv",
      },
   };
}

sub country_code_types {
   my $self = shift;

   my $data = $self->_data;
   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('update'));
   }

   my %list = ();
   for my $this (keys %$data) {
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

   my $context = $self->context;

   $context->set('www::client', 'uri', $uri) or return;
   $context->run('www::client', 'get') or return;
   my $html = $context->run('www::client', 'content') or return;

   # <tr class="iana-group-1 iana-type-2">
   #   <td><span class="domain tld"><a href="/domains/root/db/abogado.html">.abogado</a></span></td>
   #   <td>generic</td>
   #   <!-- <td>-<br/><span class="tld-table-so">Top Level Domain Holdings Limited</span></td> </td> -->
   #   <td>Top Level Domain Holdings Limited</td>
   # </tr>

   my %cc = ();

   while ($html =~ m{<tr class="iana-group-\d+\s+iana-type-\d+">(.*?)</tr>}gcs) {
      my $this = $1;

      $this =~ s/\n//g;

      $self->debug && $self->log->debug("update: this[$this]");

      #my ($tld, $type, $country, $sponsor) = ($this =~ m{^.*?<a href.*?>(.*?)<.*?<td>(.*?)<.*?<td>(.*?)<.*>(.*?)</span>.*$});
      my ($tld, $type, $country, $sponsor) = ($this =~ m{^.*?<a href.*?>(.*?)<.*?<td>(.*?)<.*?<td>(.*?)<.*<span.*?>(.*?)</span>.*$});

      #print "tld[$tld]\n";
      #print "type[$type]\n";
      #print "sponsor[$sponsor]\n";

      $cc{$tld} = {
         tld => $tld,
         country => $country,
         type => $type,
         sponsor => $sponsor,
      };
   }

   $self->_data(\%cc);

   return \%cc;
}

sub save {
   my $self = shift;

   my $context = $self->context;

   my $data = $self->_data;
   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('update'));
   }

   my $headers = join(';', qw(tld country type sponsor));
   my @lines = ();
   for my $this (keys %$data) {
      my @elts = ();
      push @elts, $data->{$this}->{tld};
      push @elts, $data->{$this}->{country};
      push @elts, $data->{$this}->{type};
      push @elts, $data->{$this}->{sponsor};
      push @lines, join(';', @elts);
   }

   $context->set('file::write', 'output', $self->output);
   $context->set('file::write', 'overwrite', 1);
   $context->set('file::write', 'append', 0);
   $context->set('file::write', 'encoding', 'utf8');

   my $out = $context->run('file::write', 'open');
   if (! defined($out)) {
      return $self->log->error('save: run open');
   }

   print $out "$headers\n";
   for my $this (@lines) {
      print $out "$this\n";
   }

   $context->run('file::write', 'close');

   return $self->output;
}

sub load {
   my $self = shift;

   my $input = $self->input;
   my $context = $self->context;

   if (! -f $input) {
      return $self->log->error("load: file [$input] not found");
   }

   $context->set('file::csv', 'input', $input);
   $context->set('file::csv', 'has_header', 1);
   $context->set('file::csv', 'format', 'hoh');
   $context->set('file::csv', 'key', 'tld');
   $context->set('file::csv', 'encoding', 'utf8');

   return $context->run('file::csv', 'read');
}

1;

__END__
