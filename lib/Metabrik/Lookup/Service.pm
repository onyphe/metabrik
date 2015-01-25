#
# $Id$
#
# lookup::service Brik
#
package Metabrik::Lookup::Service;
use strict;
use warnings;

use base qw(Metabrik::File::Csv);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable lookup service iana) ],
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(input) ],
         _load => [ qw(INTERNAL) ],
      },
      attributes_default => {
         separator => ',',
         input => 'service-names-port-numbers.csv',
      },
      commands => {
         update => [ qw(output|OPTIONAL) ],
         load => [ qw(input|OPTIONAL) ],
         from_dec => [ qw(dec_number) ],
         from_hex => [ qw(hex_number) ],
         from_string => [ qw(service_string) ],
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

   my $url = 'http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv';
   my ($file) = $self->input;

   $output ||= $self->datadir.'/'.$file;

   my $ff = Metabrik::File::Fetch->new_from_brik_init($self) or return;
   $ff->get($url, $output)
      or return $self->log->error("update: get failed");

   return $output;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->datadir.'/'.$self->input;
   if (! -f $input) {
      return $self->log->error("load: file [$input] not found");
   }

   my $data = $self->read($input)
      or return $self->log->error("load: read failed");

   return $self->_load($data);
}

sub from_dec {
   my $self = shift;
   my ($dec) = @_;

   if (! defined($dec)) {
      return $self->log->error($self->brik_help_run('from_dec'));
   }

   my $data = $self->_load || $self->load;
   if (! defined($data)) {
      return $self->log->error("from_dec: load failed");
   }

   for my $this (@$data) {
      if ($this->{'Port Number'} == $dec) {
         return $this->{'Service Name'};
      }
   }

   # No match
   return;
}

sub from_hex {
   my $self = shift;
   my ($hex) = @_;

   if (! defined($hex)) {
      return $self->log->error($self->brik_help_run('from_hex'));
   }

   my $dec = hex($hex);

   return $self->from_dec($dec);
}

sub from_string {
   my $self = shift;
   my ($string) = @_;

   if (! defined($string)) {
      return $self->log->error($self->brik_help_run('from_string'));
   }

   my $data = $self->_load || $self->load;
   if (! defined($data)) {
      return $self->log->error("from_string: load failed");
   }

   my @match = ();
   for my $this (@$data) {
      next unless length($this->{'Port Number'});
      my $service = $this->{'Service Name'};
      if ($service =~ /$string/i) {
         $self->log->verbose("from_string: match with [$service]");
         push @match, $this->{'Port Number'}.'/'.$this->{'Transport Protocol'};
      }
      elsif ($service =~ /$string/i) {
         $self->log->verbose("from_string: match with [$service]");
         push @match, $this->{'Port Number'}.'/'.$this->{'Transport Protocol'};
      }
   }

   return \@match;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Service - lookup::service Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
