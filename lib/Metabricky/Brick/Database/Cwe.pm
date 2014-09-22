#
# $Id: Cwe.pm 89 2014-09-17 20:29:29Z gomor $
#
# CWE brick
#
package Metabricky::Brick::Database::Cwe;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   file
   xml
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Metabricky::Brick::Database::Sqlite',
      'Metabricky::Brick::File::Fetch',
      'Metabricky::Brick::File::Read',
      'Metabricky::Brick::File::Zip',
   ];
}

sub help {
   return {
      'run:update' => '',
      'run:load' => '',
      'run:search' => '<pattern>',
   };
}

sub default_values {
   my $self = shift;

   return {
      file => $self->bricks->{'core::global'}->datadir."/2000.xml",
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->bricks->{'core::global'}->datadir;

   my $fetch = Metabricky::Brick::File::Fetch->new(
      output => "$datadir/2000.xml.zip",
   );

   $fetch->get('http://cwe.mitre.org/data/xml/views/2000.xml.zip')
      or return $self->log->error("can't fetch file");

   my $zip = Metabricky::Brick::File::Zip->new(
      input => "$datadir/2000.xml.zip",
      destdir => $datadir,
      bricks => $self->bricks,
   );

   $zip->uncompress or return $self->log->error("can't unzip file");

   return 1;
}

sub load {
   my $self = shift;

   my $file = $self->file;

   if (! -f $file) {
      return $self->log->info($self->help_run('update'));
   }

   my $read = Metabricky::Brick::File::Read->new(
      input => $file,
   );

   my $xml = $read->xml;

   return $self->xml($xml);
}

sub show {
   my $self = shift;
   my ($h) = @_;

   my $buf = "ID: ".$h->{id}."\n";
   $buf .= "Type: ".$h->{type}."\n";
   $buf .= "Name: ".$h->{name}."\n";
   $buf .= "Status: ".$h->{status}."\n";
   $buf .= "URL: ".$h->{url}."\n";
   $buf .= "Description Summary: ".($h->{description_summary} || '(undef)')."\n";
   $buf .= "Likelihood of Exploit: ".($h->{likelihood_of_exploit} || '(undef)')."\n";
   $buf .= "Relationships:\n";
   for my $r (@{$h->{relationships}}) {
      $buf .= "   ".$r->{relationship_nature}." ".$r->{relationship_target_form}." ".
              $r->{relationship_target_id}."\n";
   }

   return $buf;
}

sub _to_hash {
   my $self = shift;
   my ($w, $type) = @_;

   my $id = $w->{ID};
   my $name = $w->{Name};
   my $status = $w->{Status};
   my $likelihood_of_exploit = $w->{Likelihood_of_Exploit};
   my $weakness_abstraction = $w->{Weakness_Abstraction};
   my $description_summary = $w->{Description}->{Description_Summary};
   if (defined($description_summary)) {
      $description_summary =~ s/\s*\n\s*/ /gs;
   }
   my $extended_description = $w->{Description}->{Extended_Description}->{Text};
   if (defined($extended_description)) {
      $extended_description =~ s/\s*\n\s*/ /gs;
   }
   my $relationships = $w->{Relationships}->{Relationship};
   # Potential_Mitigations
   # Affected_Resources

   my @relationships = ();
   if (defined($relationships)) {
      #print "DEBUG Processing ID [$id]\n";
      #print "DEBUG ".ref($relationships)."\n";
      # $relationships can be ARRAY or HASH, we convert to ARRAY
      if (ref($relationships) eq 'HASH') {
         $relationships = [ $relationships ];
      }
      for my $r (@$relationships) {
         my $relationship_nature = $r->{Relationship_Nature};
         my $relationship_target_id = $r->{Relationship_Target_ID};
         my $relationship_target_form = $r->{Relationship_Target_Form};
         push @relationships, {
            relationship_nature => $relationship_nature,
            relationship_target_id => $relationship_target_id,
            relationship_target_form => $relationship_target_form,
         };
      }
   }

   return {
      id => $id,
      type => $type,
      name => $name,
      status => $status,
      url => 'http://cwe.mitre.org/data/definitions/'.$id.'.html',
      likelihood_of_exploit => $likelihood_of_exploit,
      description_summary => $description_summary,
      relationships => \@relationships,
   };
}

sub search {
   my $self = shift;
   my ($pattern) = @_;

   if (! defined($self->xml)) {
      return $self->log->info($self->help_run('load'));
   }

   if (! defined($pattern)) {
      return $self->log->info($self->help_run('search'));
   }

   my $xml = $self->xml;

   my @list = ();
   if (exists $xml->{Weaknesses} && exists $xml->{Weaknesses}->{Weakness}) {
      my $weaknesses = $xml->{Weaknesses}->{Weakness};
      for my $w (@$weaknesses) {
         my $this = $self->_to_hash($w, 'Weakness');
         if ($this->{name} =~ /$pattern/i || $this->{id} =~ /^$pattern$/) {
            print $self->show($this)."\n";
            push @list, $this;
         }
      }
   }

   if (exists $xml->{Categories} && exists $xml->{Categories}->{Category}) {
      my $categories = $xml->{Categories}->{Category};
      for my $c (@$categories) {
         my $this = $self->_to_hash($c, 'Category');
         if ($this->{name} =~ /$pattern/i || $this->{id} =~ /^$pattern$/) {
            print $self->show($this)."\n";
            push @list, $this;
         }
      }
   }

   # XXX: TODO: type: Compound_Element

   return \@list;
}

1;

__END__
