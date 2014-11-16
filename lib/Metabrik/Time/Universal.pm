#
# $Id$
#
# time::universal Brik
#
package Metabrik::Time::Universal;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(time timezone) ],
      attributes => {
         timezone => [ qw(string) ],
      },
      attributes_default => {
         timezone => [ 'Europe/Paris' ],
      },
      commands => {
         timezone_list => [ ],
         timezone_show => [ ],
         timezone_search => [ qw(string) ],
         localtime => [ ],
      },
      require_modules => {
         'DateTime' => [ ],
         'DateTime::TimeZone' => [ ],
      },
   };
}

sub timezone_list {
   return DateTime::TimeZone->all_names;
}

sub timezone_show {
   my $self = shift;

   my $list = $self->timezone_list;

   my $string = '';
   for my $this (@$list) {
      $string .= "$this\n";
   }

   return $string;
}

sub timezone_search {
   my $self = shift;
   my ($pattern) = @_;

   if (! defined($pattern)) {
      return $self->log->error($self->brik_help_run('timezone_search'));
   }

   my $list = $self->timezone_list;

   my @found = ();
   for my $this (@$list) {
      if ($this =~ /$pattern/i) {
         push @found, $this;
      }
   }

   return join("\n", @found);
}

sub localtime {
   my $self = shift;

   my $timezone = $self->timezone;
   if (! defined($timezone)) {
      return $self->log->error($self->brik_help_set('timezone'));
   }

   my $dt = DateTime->now(
      time_zone => $timezone,
   );

   return "$dt";
}

1;

__END__

=head1 NAME

Metabrik::Time::Universal - time::universal Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
