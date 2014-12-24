#
# $Id$
#
# database::nvd Brik
#
package Metabrik::Database::Nvd;
use strict;
use warnings;

use base qw(Metabrik::File::Fetch);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable cve cpe nvd nist) ],
      attributes => {
         datadir => [ qw(datadir) ],
         loaded_xml => [ qw(loaded_xml) ],
      },
      commands => {
         update => [ qw(recent|modified|others|all RETURN:xml_filenames) ],
         load => [ qw(recent|modified|others|all year|OPTIONAL RETURN:xml) ],
         search_all => [ qw(RETURN:all_entries_list) ],
         cve_search => [ qw(pattern RETURN:entries_list) ],
         cpe_search => [ qw(pattern RETURN:entries_list) ],
         get_cve_xml => [ qw(cve_id RETURN:entry_xml) ],
         to_hash => [ qw(entry_xml RETURN:entry_hash) ],
         to_string => [ qw(entry_hash RETURN:lines_list) ],
         print => [ qw(entry_hash) ],
      },
      require_modules => {
         'Metabrik::File::Xml' => [ ],
         'Metabrik::File::Compress' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         datadir => $self->global->datadir.'/nvd',
      },
   };
}

sub brik_init {
   my $self = shift;

   my $datadir = $self->datadir;
   if (! -d $datadir) {
      mkdir($datadir);
   }

   return $self->SUPER::brik_init(@_);
}

# http://nvd.nist.gov/download.cfm
# nvdcve-2.0-Modified.xml.gz includes all recently published and recently updated vulnerabilities.
# nvdcve-2.0-Recent.xml.gz includes all recently published vulnerabilities.
# nvdcve-2.0-2002.xml includes vulnerabilities prior to and including 2002.
my $resource = {
   uri => 'http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-NAME.xml.gz',
   gz => 'nvdcve-2.0-NAME.xml.gz',
   xml => 'nvdcve-2.0-NAME.xml',
};

sub update {
   my $self = shift;
   my ($type) = @_;

   $type ||= 'recent';

   if ($type ne 'recent'
   &&  $type ne 'modified'
   &&  $type ne 'others'
   &&  $type ne 'all') {
      return $self->log->error($self->brik_help_run('update'));
   }

   if ($type eq 'all') {
      my @output = ();
      push @output, $self->update('recent');
      push @output, $self->update('modified');
      push @output, @{$self->update('others')};
      return \@output;
   }

   my $datadir = $self->datadir;

   my $compress = Metabrik::File::Compress->new_from_brik($self);

   if ($type eq 'recent') {
      (my $uri = $resource->{uri}) =~ s/NAME/Recent/;
      (my $gz = $resource->{gz}) =~ s/NAME/Recent/;
      (my $xml = $resource->{xml}) =~ s/NAME/Recent/;
      my $output = "$datadir/$gz";
      $self->get($uri, $output) or return $self->log->error("update: get failed");
      $compress->gunzip($output, $datadir.'/'.$xml) or return $self->log->error("update: gunzip failed");
      return $datadir.'/'.$xml;
   }
   elsif ($type eq 'modified') {
      (my $uri = $resource->{uri}) =~ s/NAME/Modified/;
      (my $gz = $resource->{gz}) =~ s/NAME/Modified/;
      (my $xml = $resource->{xml}) =~ s/NAME/Modified/;
      my $output = "$datadir/$gz";
      $self->get($uri, $output) or return $self->log->error("update: get failed");
      $compress->gunzip($output, $datadir.'/'.$xml) or return $self->log->error("update: gunzip failed");
      return $datadir.'/'.$xml;
   }
   elsif ($type eq 'others') {
      my @output = ();
      for my $year (2002..2014) {
         (my $uri = $resource->{uri}) =~ s/NAME/$year/;
         (my $gz = $resource->{gz}) =~ s/NAME/$year/;
         (my $xml = $resource->{xml}) =~ s/NAME/$year/;
         my $output = "$datadir/$gz";
         $self->get($uri, $output) or return $self->log->error("update: get failed");
         $compress->gunzip($output, $datadir.'/'.$xml) or return $self->log->error("update: gunzip failed");
         push @output, $datadir.'/'.$xml;
      }
      return \@output;
   }

   # Error
   return;
}

sub _merge_xml {
   my $self = shift;
   my ($old, $new, $type) = @_;

   # Return $new, nothing to merge
   if (! defined($old)) {
      return $new;
   }

   $self->log->verbose("_merge_xml: merging XML");

   for my $k (keys %{$new->{entry}}) {
      # Check if it already exists
      if (exists $old->{entry}->{$k}) {
         # It exists. Do we load recent or modified data?
         # If so, it takes precedence, and we overwrite it.
         if ($type eq 'recent' || $type eq 'modified') {
            $old->{entry}->{$k} = $new->{entry}->{$k};
         }
      }
      # We add it directly if it does not exist yet.
      else {
         $old->{entry}->{$k} = $new->{entry}->{$k};
      }
   }

   # Return merged data into $old
   return $old;
}

sub load {
   my $self = shift;
   my ($type, $year) = @_;

   $type ||= 'recent';

   if ($type ne 'recent'
   &&  $type ne 'modified'
   &&  $type ne 'others'
   &&  $type ne 'all') {
      return $self->log->error($self->brik_help_run('load'));
   }

   if ($type eq 'all') {
      $self->load('recent') or return;
      $self->load('modified') or return;
      return $self->load('others');
   }

   my $datadir = $self->datadir;

   my $brik_xml = Metabrik::File::Xml->new_from_brik($self);

   my $old = $self->loaded_xml;

   if ($type eq 'recent') {
      (my $xml = $resource->{xml}) =~ s/NAME/Recent/;
      my $file = $datadir.'/'.$xml;

      my $new = $brik_xml->read($file) or return $self->log->error("load: read failed");

      my $merged = $self->_merge_xml($old, $new, $type);

      return $self->loaded_xml($merged);
   }
   elsif ($type eq 'modified') {
      (my $xml = $resource->{xml}) =~ s/NAME/Modified/;
      my $file = $datadir.'/'.$xml;

      my $new = $brik_xml->read($file) or return $self->log->error("load: read failed");

      my $merged = $self->_merge_xml($old, $new, $type);

      return $self->loaded_xml($merged);
   }
   elsif ($type eq 'others') {
      my $merged = $old;
      my @years = defined($year) ? ( $year ) : ( 2002..2014 );
      for my $year (@years) {
         (my $xml = $resource->{xml}) =~ s/NAME/$year/;
         my $file = $datadir.'/'.$xml;

         my $new = $brik_xml->read($file) or return $self->log->error("load: read failed");

         $merged = $self->_merge_xml($merged, $new, $type);
      }

      return $self->loaded_xml($merged);
   }

   # Error
   return;
}

sub to_string {
   my $self = shift;
   my ($h) = @_;

   my @buf = ();
   push @buf, "CVE: ".$h->{cve_id};
   push @buf, "CWE: ".$h->{cwe_id};
   push @buf, "Published datetime: ".$h->{published_datetime};
   push @buf, "Last modified datetime: ".$h->{last_modified_datetime};
   push @buf, "URL: ".$h->{url};
   push @buf, "Summary: ".($h->{summary} || '(undef)');
   push @buf, "Vuln product:";
   for my $vuln_product (@{$h->{vuln_product}}) {
      push @buf, "   $vuln_product";
   }

   return \@buf;
}

sub print {
   my $self = shift;
   my ($h) = @_;

   if (! defined($h)) {
      return $self->log->error($self->brik_help_run('print'));
   }

   my $lines = $self->to_string($h);
   for my $line (@$lines) {
      print $line."\n";
   }

   return 1;
}

sub to_hash {
   my $self = shift;
   my ($h) = @_;

   my $cve = $h->{'vuln:cve-id'};

   my $published_datetime = $h->{'vuln:published-datetime'};
   my $last_modified_datetime = $h->{'vuln:last-modified-datetime'};
   my $summary = $h->{'vuln:summary'};
   my $cwe_id = $h->{'vuln:cwe'}->{id} || '(undef)';
   $cwe_id =~ s/^CWE-//;

   my $vuln_product = [];
   if (defined($h->{'vuln:vulnerable-software-list'})
   &&  defined($h->{'vuln:vulnerable-software-list'}->{'vuln:product'})) {
      my $e = $h->{'vuln:vulnerable-software-list'}->{'vuln:product'};
      if (ref($e) eq 'ARRAY') {
         $vuln_product = $e;
      }
      else {
         $vuln_product = [ $e ];
      }
   }

   return {
      cve_id => $cve,
      url => 'http://web.nvd.nist.gov/view/vuln/detail?vulnId='.$cve,
      published_datetime => $published_datetime,
      last_modified_datetime => $last_modified_datetime,
      summary => $summary,
      cwe_id => $cwe_id,
      vuln_product => $vuln_product,
   };
}

sub search_all {
   my $self = shift;

   my $xml = $self->loaded_xml;
   if (! defined($xml)) {
      return $self->log->error($self->brik_help_run('load'));
   }

   my $entries = $xml->{entry};
   if (! defined($entries)) {
      return $self->log->error("search_all: no entry found");
   }

   my @entries = ();
   for my $cve (keys %$entries) {
      my $this = $self->to_hash($entries->{$cve});
      push @entries, $this;
   }

   return \@entries;
}

sub cve_search {
   my $self = shift;
   my ($pattern) = @_;

   my $xml = $self->loaded_xml;
   if (! defined($xml)) {
      return $self->log->error($self->brik_help_run('load'));
   }

   if (! defined($pattern)) {
      return $self->log->error($self->brik_help_run('cve_search'));
   }

   my $entries = $xml->{entry};
   if (! defined($entries)) {
      return $self->log->error("cve_search: no entry found");
   }

   my @entries = ();
   for my $cve (keys %$entries) {
      my $this = $self->to_hash($entries->{$cve});

      if ($this->{cve_id} =~ /$pattern/ || $this->{summary} =~ /$pattern/i) {
         push @entries, $this;
         $self->print($this);
      }
   }

   return \@entries;
}

sub cpe_search {
   my $self = shift;
   my ($cpe) = @_;

   my $xml = $self->loaded_xml;
   if (! defined($xml)) {
      return $self->log->error($self->brik_help_run('load'));
   }

   if (! defined($cpe)) {
      return $self->log->error($self->brik_help_run('cpe_search'));
   }

   my $entries = $xml->{entry};
   if (! defined($entries)) {
      return $self->log->error("cpe_search: no entry found");
   }

   my @entries = ();
   for my $cve (keys %$entries) {
      my $this = $self->to_hash($entries->{$cve});

      for my $vuln_product (@{$this->{vuln_product}}) {
         if ($vuln_product =~ /$cpe/i) {
            push @entries, $this;
            $self->print($this);
            last;
         }
      }
   }

   return \@entries;
}

sub get_cve_xml {
   my $self = shift;
   my ($cve_id) = @_;

   my $xml = $self->loaded_xml;
   if (! defined($xml)) {
      return $self->log->error($self->brik_help_run('load'));
   }

   if (defined($xml->{entry})) {
      return $xml->{entry}->{$cve_id};
   }

   return;
}

1;

__END__

=head1 NAME

Metabrik::Database::Nvd - database::nvd Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
