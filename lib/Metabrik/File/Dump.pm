#
# $Id$
#
# file::dump Brik
#
package Metabrik::File::Dump;
use strict;
use warnings;

use base qw(Metabrik::File::Write);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable read write) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         append => [ qw(0|1) ],
      },
      attributes_default => {
         append => 1,
      },
      commands => {
         read => [ qw(file) ],
         write => [ qw($data|$data_ref|$data_list output|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Read' => [ ],
         'Data::Dump' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('read'));
   }

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->input($input);
   $fr->encoding($self->encoding);
   $fr->as_array(1);
   $fr->strip_crlf(1);

   $fr->open or return $self->log->error("read: open failed");
   my $data = $fr->read or return $self->log->error("read: read failed");
   $fr->close;

   my @vars = ();
   my $buf = '';
   for (@$data) {
      $buf .= $_;

      if (/^$/) {
         push @vars, $buf;
         $buf = '';
      }
   }

   # Gather last remaining line, if any
   if (length($buf)) {
      push @vars, $buf;
      $buf = '';
   }

   my @res = ();
   for (@vars) {
      my $h = eval($_);
      if ($@) {
         chomp($@);
         $self->log->warning("read: eval failed: $@");
         next;
      }
      push @res, $h;
   }

   return \@res;
}

sub write {
   my $self = shift;
   my ($data, $output) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $output ||= $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $self->debug && $self->log->debug("write: data[$data]");

   $self->open($output) or return $self->log->error("write: open failed");

   if (ref($data) eq 'ARRAY') {
      for (@$data) {
         my $r = $self->SUPER::write(Data::Dump::dump($_)."\n\n");
         if (! defined($r)) {
            return $self->log->error("write: write failed");
         }
      }
   }
   else {
      my $r = $self->SUPER::write(Data::Dump::dump($data)."\n\n");
      if (! defined($r)) {
         return $self->log->error("write: write failed");
      }
   }

   $self->close;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Dump - file::dump Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
