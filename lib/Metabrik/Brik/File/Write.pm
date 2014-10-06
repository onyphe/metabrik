#
# $Id$
#
# file::write Brik
#
package Metabrik::Brik::File::Write;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_tags {
   return [ qw(main file) ];
}

sub declare_attributes {
   return [ qw(output append overwrite) ];
}

sub require_modules {
   return {
      'JSON::XS' => [],
      'XML::Simple' => [],
      'Text::CSV::Hashify' => [],
   };
}

sub help {
   return {
      'set:output' => '<file>',
      'set:append' => '<0|1>',
      'set:overwrite' => '<0|1>',
      'run:text' => '<data>',
   };
}

sub default_values {
   my $self = shift;

   return {
      output => $self->global->output || '/tmp/output.txt',
      append => 1,
      overwrite => 0,
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
