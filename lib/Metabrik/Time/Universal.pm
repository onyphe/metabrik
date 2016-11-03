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
         separator => [ qw(character) ],
      },
      attributes_default => {
         timezone => [ 'Europe/Paris' ],
         separator => '-',
      },
      commands => {
         list_timezones => [ ],
         search_timezone => [ qw(string) ],
         localtime => [ qw(timezone|OPTIONAL) ],
         today => [ qw(separator|OPTIONAL) ],
         yesterday => [ qw(separator|OPTIONAL) ],
         date => [ ],
         gmdate => [ ],
         month => [ qw(timezone|OPTIONAL) ],
         last_month => [ qw(timezone|OPTIONAL) ],
         is_timezone => [ qw(timezone) ],
         timestamp => [ ],
      },
      require_modules => {
         'DateTime' => [ ],
         'DateTime::TimeZone' => [ ],
         'POSIX' => [ qw(strftime) ],
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
         if (! $self->is_timezone($tz)) {
            $self->log->warning("localtime: invalid timezone [$timezone]");
            next;
         }
         my $dt = DateTime->now(
            time_zone => $tz,
         );
         $time->{$tz} = "$dt";
      }
   }
   else {
      if (! $self->is_timezone($timezone)) {
         return $self->log->error("localtime: invalid timezone [$timezone]");
      }
      my $dt = DateTime->now(
         time_zone => $timezone,
      );
      $time->{$timezone} = "$dt";
   }

   return $time;
}

sub today {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime();
   my $y = $a[5] + 1900;
   my $m = $a[4] + 1;
   my $d = $a[3];

   return sprintf("%04d$sep%02d$sep%02d", $y, $m, $d);
}

sub yesterday {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime(time() - (24 * 3600));
   my $y = $a[5] + 1900;
   my $m = $a[4] + 1;
   my $d = $a[3];

   return sprintf("%04d$sep%02d$sep%02d", $y, $m, $d);
}

sub date {
   my $self = shift;

   return CORE::localtime()."";
}

sub gmdate {
   my $self = shift;

   eval("use POSIX qw(strftime);");

   return strftime("%a %b %e %H:%M:%S %Y", CORE::gmtime());
}

sub month {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime();
   my $y = $a[5] + 1900;
   my $m = $a[4] + 1;

   return sprintf("%04d$sep%02d", $y, $m);
}

sub last_month {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime();
   my $y = $a[5] + 1900;
   my $m = $a[4];

   if ($m == 0) {
      $m = 12;
      $y -= 1;
   }

   return sprintf("%04d$sep%02d", $y, $m);
}

sub is_timezone {
   my $self = shift;
   my ($tz) = @_;

   $self->brik_help_run_undef_arg('is_timezone', $tz) or return;

   my $tz_list = $self->list_timezones;
   my %h = map { $_ => 1 } @$tz_list;

   return exists($h{$tz}) ? 1 : 0;
}

sub timestamp {
   my $self = shift;

   return CORE::time();
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
