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
      tags => [ qw(unstable timezone) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         timezone => [ qw(string) ],
      },
      attributes_default => {
         timezone => [ 'Europe/Paris' ],
      },
      commands => {
         list_timezones => [ ],
         search_timezone => [ qw(string) ],
         localtime => [ qw(timezone|OPTIONAL) ],
         today => [ ],
         date => [ ],
      },
      require_modules => {
         'DateTime' => [ ],
         'DateTime::TimeZone' => [ ],
      },
   };
}

sub list_timezones {
   my $self = shift;

   return DateTime::TimeZone->all_names;
}

sub search_timezone {
   my $self = shift;
   my ($pattern) = @_;

   $self->brik_help_run_undef_arg('search_timezone', $pattern) or return;

   my $list = $self->list_timezones;

   my @found = ();
   for my $this (@$list) {
      if ($this =~ /$pattern/i) {
         push @found, $this;
      }
   }

   return \@found;
}

sub localtime {
   my $self = shift;
   my ($timezone) = @_;

   $timezone ||= $self->timezone;
   $self->brik_help_run_undef_arg('localtime', $timezone) or return;

   my $time = {};
   if (ref($timezone) eq 'ARRAY') {
      for my $tz (@$timezone) {
         my $dt = DateTime->now(
            time_zone => $tz,
         );
         $time->{$tz} = "$dt";
      }
   }
   else {
      my $dt = DateTime->now(
         time_zone => $timezone,
      );
      $time->{$timezone} = "$dt";
   }

   return $time;
}

sub today {
   my $self = shift;

   my @a = CORE::localtime();
   my $y = $a[5] + 1900;
   my $m = $a[4] + 1;
   my $d = $a[3];

   return "$y-$m-$d";
}

sub date {
   my $self = shift;

   return CORE::localtime()."";
}

1;

__END__

=head1 NAME

Metabrik::Time::Universal - time::universal Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
