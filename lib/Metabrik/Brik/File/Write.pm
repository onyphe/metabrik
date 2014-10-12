#
# $Id$
#
# file::write Brik
#
package Metabrik::Brik::File::Write;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub properties {
   my $self = shift;

   return {
      revision => '$Revision$',
      tags => [ qw(main file) ],
      attributes => {
         output => [ qw(SCALAR) ],
         append => [ qw(SCALAR) ],
         overwrite => [ qw(SCALAR) ],
      },
      attributes_default => {
         output => $self->global->output || '/tmp/output.txt',
         append => 1,
         overwrite => 0,
      },
      commands => {
         text => [ qw(SCALAR SCALARREF) ],
      },
      require_modules => {
         'JSON::XS' => [ ],
         'XML::Simple' => [ ],
         'Text::CSV::Hashify' => [ ],
      },
   };
}

sub text {
   my $self = shift;
   my ($data) = @_;

   $self->debug && $self->log->debug("text: data[$data]");

   if (! defined($self->output)) {
      return $self->log->info($self->help_set('output'));
   }

   if (! defined($data)) {
      return $self->log->info($self->help_run('text'));
   }

   if ($self->append) {
      my $r = open(my $out, '>>', $self->output);
      if (! defined($r)) {
         return $self->log->error("text: append file [".$self->output."]: $!");
      }

      ref($data) eq 'SCALAR' ? print $out $$data : print $out $data;

      close($out);
   }
   elsif (! $self->append && ! $self->overwrite && -f $self->output) {
      $self->log->info("text: we will not overwrite an existing file. See:");
      return $self->log->info($self->help_set('overwrite'));
   }
   else {
      my $r = open(my $out, '>', $self->output);
      if (! defined($r)) {
         return $self->log->error("text: write file [".$self->output."]: $!");
      }

      ref($data) eq 'SCALAR' ? print $out $$data : print $out $data;

      close($out);
   }

   return $data;
}

1;

__END__
