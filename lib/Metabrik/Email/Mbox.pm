#
# $Id$
#
# email::mbox Brik
#
package Metabrik::Email::Mbox;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable email mbox) ],
      attributes => {
         input => [ qw(mbox_file) ],
         _folder => [ qw(INTERNAL) ],
      },
      commands => {
         open => [ qw(mbox_file|OPTIONAL) ],
         read => [ ],
         read_all => [ ],
         close => [ ],
      },
      require_modules => {
         'Email::Folder' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($mbox) = @_;

   $mbox ||= $self->input;

   if (! defined($mbox)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $folder = Email::Folder->new($mbox);
   if (! defined($folder)) {
      return $self->log->error("open: Email::Folder new failed for mbox [$mbox]");
   }

   return $self->_folder($folder);
}

sub read_all {
   my $self = shift;

   my $folder = $self->_folder;
   if (! defined($folder)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my @messages = ();
   for my $message ($folder->messages) {
      my $subject = $message->header('Subject');
      $self->log->verbose("read: Subject [$subject]");

      push @messages, $message;
   }

   return \@messages;
}

sub read {
   my $self = shift;

   my $folder = $self->_folder;
   if (! defined($folder)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $message = $folder->next_message;

   return $message;
}

sub close {
   my $self = shift;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Email::Mbox - email::mbox Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
