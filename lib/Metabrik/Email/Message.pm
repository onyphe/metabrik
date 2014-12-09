#
# $Id$
#
# email::message Brik
#
package Metabrik::Email::Message;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable email message) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         subject => [ qw(subject|OPTIONAL) ],
         from => [ qw(from|OPTIONAL) ],
         to => [ qw(to|OPTIONAL) ],
      },
      attributes_default => {
         from => 'from@example.com',
         to => 'to@example.com',
         subject => 'Example.com subject',
      },
      commands => {
         create => [ qw(content) ],
      },
      require_modules => {
         'Email::Simple' => [ ],
      },
   };
}

sub create {
   my $self = shift;
   my ($content) = @_;

   if (! defined($content)) {
      return $self->log->error($self->brik_help_run('create'));
   }

   my $from = $self->from;
   my $to = $self->to;
   my $subject = $self->subject;

   my $email = Email::Simple->create(
      header => [
         From => $from,
         To => $to,
         Subject => $subject,
      ],
      body => $content,
   );

   return $email;
}

1;

__END__

=head1 NAME

Metabrik::Email::Message - email::message Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
