#
# $Id$
#
# file::json Brik
#
package Metabrik::File::Json;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable json file) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         write => [ qw($json_hash output_file|OPTIONAL) ],
      },
      require_used => {
         'file::read' => [ ],
         'file::write' => [ ],
         'encoding::json' => [ ],
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

   $context->save_state('file::read') or return;

   $context->set('file::read', 'input', $input) or return;
   my $fd = $context->run('file::read', 'open') or return;
   my $data = $context->run('file::read', 'readall') or return;
   $context->run('file::read', 'close') or return;

   my $json = $context->run('encoding::json', 'decode', $data) or return;

   $context->restore_state('file::read');

   return $json;
}

sub write {
   my $self = shift;
   my ($json_hash, $output) = @_;

   if (! defined($json_hash)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $output ||= $self->output;

   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   my $context = $self->context;

   my $data = $context->run('encoding::json', 'encode', $json_hash) or return;

   $context->save_state('file::write') or return;

   $context->set('file::write', 'output', $output) or return;
   my $fd = $context->run('file::write', 'open') or return;
   $context->run('file::write', 'write', $data) or return;
   $context->run('file::write', 'close') or return;

   $context->restore_state('file::write');

   return $data;
}

1;

__END__
