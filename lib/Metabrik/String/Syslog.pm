#
# $Id$
#
# string::syslog Brik
#
package Metabrik::String::Syslog;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         hostname => [ qw(hostname) ],
         process => [ qw(name) ],
         pid => [ qw(id) ],
      },
      attributes_default => {
         process => 'metabrik',
         pid => '0',
      },
      commands => {
         encode => [ qw($data hostname|OPTIONAL process|OPTIONAL pid|OPTIONAL) ],
         decode => [ qw($data) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         hostname => $self->global->hostname,
      },
   };
}

sub encode {
   my $self = shift;
   my ($data, $hostname, $process, $pid) = @_;

   $hostname ||= $self->hostname;
   $process ||= $self->process;
   $pid ||= $self->pid;
   $self->brik_help_run_undef_arg('encode', $data) or return;
   $self->brik_help_run_undef_arg('encode', $hostname) or return;
   $self->brik_help_run_undef_arg('encode', $process) or return;
   $self->brik_help_run_undef_arg('encode', $pid) or return;
   $self->brik_help_run_invalid_arg('encode', $data, 'SCALAR') or return;

   my @month = qw{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec};

   # Courtesy of Net::Syslog
   my @time = localtime();
   my $timestamp =
      $month[$time[4]].
      ' '.
      (($time[3] < 10) ? (' '.$time[3]) : $time[3]).
      ' '.
      (($time[2] < 10 ) ? ('0'.$time[2]) : $time[2]).
      ':'.
      (($time[1] < 10) ? ('0'.$time[1]) : $time[1]).
      ':'.
      (($time[0] < 10) ? ('0'.$time[0]) : $time[0]);

   return "$timestamp $hostname $process\[$pid\]: $data";
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;
   $self->brik_help_run_invalid_arg('encode', $data, 'SCALAR') or return;

   my ($m, $d, $h, $hostname, $process, $pid, $message) =
      $data =~ m{^(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\[(\d+)\]:\s+(.*)$};

   return {
      timestamp => sprintf("%s %2d %s", $m, $d, $h),
      hostname => $hostname,
      process => $process,
      pid => $pid,
      message => $message,
   };
}

1;

__END__

=head1 NAME

Metabrik::String::Syslog - string::syslog Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
