#
# $Id$
#
# network::grep Brik
#
package Metabrik::Network::Grep;
use strict;
use warnings;

use base qw(Metabrik::Network::Read);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         filter => [ qw(filter) ],
      },
      attributes_default => {
      },
      commands => {
         from_string => [ qw(string filter|OPTIONAL device|OPTIONAL) ],
      },
      require_modules => {
         'Net::Frame::Simple' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device,
      },
   };
}

sub from_string {
   my $self = shift;
   my ($string, $filter, $device) = @_;

   $device ||= $self->device;
   $filter ||= '';
   if (! defined($string)) {
      return $self->log->error($self->brik_help_run('from_string'));
   }
   if (! defined($device)) {
      return $self->log->error($self->brik_help_set('device'));
   }

   $self->open(2, $device, $filter) or return;

   {
      # So we can interrupt execution
      local $SIG{INT} = sub {
         die("interrupted by user\n");
      };

      while (1) {
         my $h = $self->next or next;
         my $simple = Net::Frame::Simple->newFromDump($h) or next;
         my $layer = $simple->ref->{TCP} || $simple->ref->{UDP};
         if (defined($layer) && length($layer->payload)) {
            my $payload = $layer->payload;
            if ($payload =~ /$string/) {
               $self->log->info("payload: [$payload]");
            }
         }
      }
   };

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Network::Grep - network::grep Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
