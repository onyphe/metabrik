#
# $Id$
#
# harware::battery Brik
#
package Metabrik::Hardware::Battery;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable hardware battery) ],
      commands => {
         capacity => [ ],
      },
      require_used => {
         'file::read' => [ ],
      },
   };
}

sub capacity {
   my $self = shift;

   my $context = $self->context;

   my $base_file = '/sys/class/power_supply/BAT';

   $context->save_state('file::read') or return;

   my $battery_hash = {};
   my $count = 0;
   while (-f "$base_file$count/capacity") {
      $context->set('file::read', 'input', "$base_file$count/capacity");
      $context->run('file::read', 'open') or next;

      chomp(my $data = $context->run('file::read', 'readall'));

      $context->run('file::read', 'close');

      my $this = sprintf("battery_%02d", $count);
      $battery_hash->{$this} = {
         battery => $count,
         capacity => $data,
      };

      $count++;
   }

   $context->restore_state('file::read');

   return $battery_hash;
}

1;

__END__
