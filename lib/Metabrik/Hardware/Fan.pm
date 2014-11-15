#
# $Id$
#
# harware::fan Brik
#
package Metabrik::Hardware::Fan;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable hardware fan) ],
      commands => {
         info => [ ],
         #status => [ ],
         #speed => [ ],
         #level => [ ],
      },
      require_used => {
         'file::read' => [ ],
      },
   };
}

sub info {
   my $self = shift;

   my $context = $self->context;

   my $base_file = '/proc/acpi/ibm/fan';

   if (! -f $base_file) {
      return $self->log->error("info: cannot find file [$base_file]");
   }

   my $old = $context->get('file::read', 'input');

   $context->set('file::read', 'input', $base_file);
   $context->run('file::read', 'open')
      or return;
   my $data = $context->run('file::read', 'readall');
   $context->run('file::read', 'close');

   my $info_hash = {};

   my @lines = split(/\n/, $data);
   for my $line (split(/\n/, $data)) {
      my ($name, $value) = $line =~ /^(\S+):\s+(.*)$/;

      if ($name eq 'commands') {
         push @{$info_hash->{$name}}, $value;
      }
      else {
         $info_hash->{$name} = $value;
      }
   }

   $context->set('file::read', 'input', $old);

   return $info_hash;
}

1;

__END__
