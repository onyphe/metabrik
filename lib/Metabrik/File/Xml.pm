#
# $Id$
#
# file::xml Brik
#
package Metabrik::File::Xml;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable xml file) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         write => [ qw($xml_hash output_file|OPTIONAL) ],
      },
      require_used => {
         'file::read' => [ ],
         'file::write' => [ ],
         'encoding::xml' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->input || '/tmp/input.txt',
         output => $self->global->output || '/tmp/output.txt',
         encoding => $self->global->encoding || 'utf8',
         overwrite => 1,
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;

   if (! defined($input)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   my $context = $self->context;

   my $old = $context->get('file::read', 'input');

   $context->set('file::read', 'input', $input) or return;
   my $fd = $context->run('file::read', 'open') or return;
   my $data = $context->run('file::read', 'readall') or return;
   $context->run('file::read', 'close') or return;

   my $xml = $context->run('encoding::xml', 'decode', $data) or return;

   $context->set('file::read', 'input', $old);

   return $xml;
}

sub write {
   my $self = shift;
   my ($xml_hash, $output) = @_;

   if (! defined($xml_hash)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $output ||= $self->output;

   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   my $context = $self->context;

   my $data = $context->run('encoding::xml', 'encode', $xml_hash) or return;

   my $old = $context->get('file::write', 'output');

   $context->set('file::write', 'output', $output) or return;
   my $fd = $context->run('file::write', 'open') or return;
   $context->run('file::write', 'write', $data) or return;
   $context->run('file::write', 'close') or return;

   $context->set('file::write', 'output', $old);

   return $data;
}

1;

__END__
