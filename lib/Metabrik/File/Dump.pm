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
      tags => [ qw(unstable file dump read write) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
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

   my $read = Metabrik::File::Read->new_from_brik($self) or return;
   $read->input($input);
   $read->encoding($self->encoding);
   $read->as_array(1);
   $read->strip_crlf(1);

   $read->open or return $self->log->error("read: open failed");
   my $data = $read->readall or return $self->log->error("read: read failed");
   $read->close;

   my @vars = ();
   for my $line (@$data) {
      my $this = eval($line);
      if ($@) {
         chomp($@);
         $self->log->warning("read: eval failed: $@");
         next;
      }
      push @vars, $this;
   }

   return \@vars;
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
   my $r = $self->SUPER::write(Data::Dump::dump($data)."\n");
   if (! defined($r)) {
      return $self->log->error("write: write failed");
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
