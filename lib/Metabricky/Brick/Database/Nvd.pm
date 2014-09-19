#
# $Id: Nvd.pm 89 2014-09-17 20:29:29Z gomor $
#
# NVD brick
#
package Metabricky::Brick::Database::Nvd;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   uri_recent
   uri_modified
   uri_others
   xml_recent
   xml_modified
   xml_others
   xml
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Metabricky::Brick::File::Fetch',
      'Metabricky::Brick::File::Slurp',
   ];
}

sub help {
   return [
      'run database::nvd update <[recent|modified|others]>',
      'run database::nvd load <[recent|modified|others]> [ <pattern> ]',
      'run database::nvd search <pattern>',
      'run database::nvd searchbycpe <cpe>',
      'run database::nvd getxml <cve_id>',
   ];
}

sub default_values {
   my $self = shift;

   my $datadir = $self->bricks->{'core::global'}->datadir;

   # http://nvd.nist.gov/download.cfm
   # nvdcve-2.0-modified.xml includes all recently published and recently updated vulnerabilities
   # nvdcve-2.0-recent.xml includes all recently published vulnerabilities
   # nvdcve-2.0-2002.xml includes vulnerabilities prior to and including 2002.
   return {
      uri_recent => [ 'http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-recent.xml', ],
      uri_modified => [ 'http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-modified.xml', ],
      uri_others => [ qw(
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2002.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2003.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2004.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2005.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2006.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2007.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2008.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2009.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2010.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2011.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2012.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2013.xml
         http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-2014.xml
      ) ],
      xml_recent => [ "$datadir/nvdcve-2.0-recent.xml", ],
      xml_modified => [ "$datadir/nvdcve-2.0-modified.xml", ],
      xml_others => [
         "$datadir/nvdcve-2.0-2002.xml",
         "$datadir/nvdcve-2.0-2003.xml",
         "$datadir/nvdcve-2.0-2004.xml",
         "$datadir/nvdcve-2.0-2005.xml",
         "$datadir/nvdcve-2.0-2006.xml",
         "$datadir/nvdcve-2.0-2007.xml",
         "$datadir/nvdcve-2.0-2008.xml",
         "$datadir/nvdcve-2.0-2009.xml",
         "$datadir/nvdcve-2.0-2010.xml",
         "$datadir/nvdcve-2.0-2011.xml",
         "$datadir/nvdcve-2.0-2012.xml",
         "$datadir/nvdcve-2.0-2013.xml",
         "$datadir/nvdcve-2.0-2014.xml",
      ],
   };
}

sub update {
   my $self = shift;
   my ($type) = @_;

   if (! defined($type)) {
      return $self->log->info("run database::nvd update <[recent|modified|others]>");
   }

   if ($type ne 'recent'
   &&  $type ne 'modified'
   &&  $type ne 'others') {
      return $self->log->info("run database::nvd update <[recent|modified|others]>");
   }

   my $datadir = $self->bricks->{'core::global'}->datadir;
   my $xml_method = "xml_$type";
   my $xml_files = $self->$xml_method;
   my $uri_method = "uri_$type";
   my $uri_list = $self->$uri_method;
   my $count = scalar @$xml_files;

   for my $c (0..$count-1) {
      my $fetch = Metabricky::Brick::File::Fetch->new(
         output => $xml_files->[$c],
      );
      $fetch->get($uri_list->[$c]) or $self->log->error("fetch::get: uri[".$uri_list->[$c]."]");
   }

   return 1;
}

sub load {
   my $self = shift;
   my ($type, $pattern) = @_;

   if (! defined($type)) {
      return $self->log->info("run database::nvd load <[recent|modified|others]> [ <pattern> ]");
   }

   if ($type ne 'recent'
   &&  $type ne 'modified'
   &&  $type ne 'others') {
      return $self->log->info("run database::nvd load <[recent|modified|others]> [ <pattern> ]");
   }

   my $datadir = $self->bricks->{'core::global'}->datadir;
   my $xml_method = "xml_$type";
   my $xml_files = $self->$xml_method;
   my $count = scalar @$xml_files;

   my $old_xml = $self->xml;
   for my $c (0..$count-1) {
      my $file = $xml_files->[$c];
      # If file does not match user pattern, we don't load it
      if (defined($pattern) && $file !~ /$pattern/) {
         next;
      }
      my $slurp = Metabricky::Brick::File::Slurp->new(
         file => $file,
      );
      print "DEBUG Slurping file: ".$xml_files->[$c]."\n";
      my $xml = $slurp->xml or return $self->log->error("load::slurp::xml");

      # Merge XML data
      if (defined($old_xml)) {
         print "DEBUG Merging\n";
         for my $k (keys %{$xml->{entry}}) {
            # Check if it already exists
            if (exists $old_xml->{entry}->{$k}) {
               # It exists. Do we load recent or modified data?
               # If so, it takes precedence, and we overwrite it.
               if ($type eq 'recent' || $type eq 'modified') {
                  $old_xml->{entry}->{$k} = $xml->{entry}->{$k};
               }
            }
            # We add it directly if it does not exist yet.
            else {
               $old_xml->{entry}->{$k} = $xml->{entry}->{$k};
            }
         }
      }
      # There was nothing previously, we write everything.
      else {
         $old_xml = $xml;
      }
   }

   return $self->xml($old_xml);
}

sub show {
   my $self = shift;
   my ($h) = @_;

   my $buf = "CVE: ".$h->{cve_id}."\n";
   $buf .= "CWE: ".$h->{cwe_id}."\n";
   $buf .= "Published datetime: ".$h->{published_datetime}."\n";
   $buf .= "Last modified datetime: ".$h->{last_modified_datetime}."\n";
   $buf .= "URL: ".$h->{url}."\n";
   $buf .= "Summary: ".($h->{summary} || '(undef)')."\n";
   $buf .= "Vuln product:\n";
   for my $vuln_product (@{$h->{vuln_product}}) {
      $buf .= "   $vuln_product\n";
   }

   return $buf;
}

sub _to_hash {
   my $self = shift;
   my ($h, $cve) = @_;

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

sub search {
   my $self = shift;
   my ($pattern) = @_;

   my $xml = $self->xml;
   if (! defined($xml)) {
      return $self->log->info("run database::nvd load <[recent|modified|others]> [ <pattern> ]");
   }

   if (! defined($pattern)) {
      return $self->log->info("run database::nvd search <pattern>");
   }

   my $entries = $xml->{entry};
   if (! defined($entries)) {
      return $self->log->error("nothing in this xml file");
   }

   my @entries = ();
   for my $cve (keys %$entries) {
      my $this = $self->_to_hash($entries->{$cve}, $cve);

      if ($this->{cve_id} =~ /$pattern/ || $this->{summary} =~ /$pattern/i) {
         push @entries, $this;
         print $self->show($this)."\n";
      }
   }

   return \@entries;
}

sub searchbycpe {
   my $self = shift;
   my ($cpe) = @_;

   my $xml = $self->xml;
   if (! defined($xml)) {
      return $self->log->info("run database::nvd load <[recent|modified|others]> [ <pattern> ]");
   }

   if (! defined($cpe)) {
      return $self->log->info("run database::nvd searchbycpe <cpe>");
   }

   my $entries = $xml->{entry};
   if (! defined($entries)) {
      return $self->log->error("nothing in this xml file");
   }

   my @entries = ();
   for my $cve (keys %$entries) {
      my $this = $self->_to_hash($entries->{$cve}, $cve);

      for my $vuln_product (@{$this->{vuln_product}}) {
         if ($vuln_product =~ /$cpe/i) {
            push @entries, $this;
            print $self->show($this)."\n";
            last;
         }
      }
   }

   return \@entries;
}

sub getxml {
   my $self = shift;
   my ($cve_id) = @_;

   my $xml = $self->xml;
   if (! defined($xml)) {
      return $self->log->info("run database::nvd load <[recent|modified|others]> [ <pattern> ]");
   }

   if (defined($xml->{entry})) {
      return $xml->{entry}->{$cve_id};
   }

   return;
}

1;

__END__
