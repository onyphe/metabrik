#
# $Id$
#
# remote::sandbox Brik
#
package Metabrik::Remote::Sandbox;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         imap_uri => [ qw(uri) ],
         _ci => [ qw(INTERNAL) ],
         _em => [ qw(INTERNAL) ],
         _fb => [ qw(INTERNAL) ],
         _sf => [ qw(INTERNAL) ],
         _fr => [ qw(INTERNAL) ],
      },
      attributes_default => {
      },
      commands => {
         create_imap_client => [ qw(imap_uri|OPTIONAL) ],
         reset_imap_client => [ qw(imap_uri|OPTIONAL) ],
         read_next_email_with_attachment => [ qw(imap_uri|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Client::Imap' => [ ],
         'Metabrik::Email::Message' => [ ],
         'Metabrik::File::Base64' => [ ],
         'Metabrik::File::Raw' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
      },
   };
}

sub brik_preinit {
   my $self = shift;

   # Do your preinit here, return 0 on error.

   return $self->SUPER::brik_preinit;
}

sub brik_init {
   my $self = shift;

   # Do your init here, return 0 on error.

   return $self->SUPER::brik_init;
}

sub create_imap_client {
   my $self = shift;
   my ($imap_uri) = @_;

   $imap_uri ||= $self->imap_uri;
   $self->brik_help_set_undef_arg('create_imap_client', $imap_uri) or return;

   my $ci = $self->_ci;
   if (! defined($ci)) {
      $ci = Metabrik::Client::Imap->new_from_brik_init($self) or return;
      $ci->open($imap_uri) or return;
      $self->_ci($ci);

      my $em = Metabrik::Email::Message->new_from_brik_init($self) or return;
      $self->_em($em);

      my $fb = Metabrik::File::Base64->new_from_brik_init($self) or return;
      $self->_fb($fb);

      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      $self->_sf($sf);

      my $fr = Metabrik::File::Raw->new_from_brik_init($self) or return;
      $fr->encoding('ascii');
      $self->_fr($fr);
   }

   return $ci;
}

sub reset_imap_client {
   my $self = shift;

   my $ci = $self->_ci;
   if (defined($ci)) {
      $ci->close;
      $self->_ci(undef);
   }

   return 1;
}

sub read_next_email_with_attachment {
   my $self = shift;
   my ($imap_uri) = @_;

   $imap_uri ||= $self->imap_uri;
   $self->brik_help_set_undef_arg('read_next_email_with_attachment', $imap_uri) or return;

   my $ci = $self->create_imap_client($imap_uri);
   my $em = $self->_em;
   my $fb = $self->_fb;
   my $sf = $self->_sf;
   my $fr = $self->_fr;

   my $total = $ci->total;
   for (1..$total) {
      my $next = $ci->read_next or return;
      my $message = $em->parse($next) or return;
      my $headers = $message->[0];
      my @files = ();
      for my $part (@$message) {
         if (exists($part->{filename}) && length($part->{filename})) {
            my $from = $headers->{From};
            my $to = $headers->{To};
            my $subject = $headers->{Subject};
            my $filename = $sf->basefile($part->{filename});
            $filename =~ s{\s+}{_}g; # I hate spaces in filenames.
            my $output = $fb->decode_from_string(
               $part->{file_content}, $self->datadir."/$filename"
            );
            push @files, {
               headers => $headers,
               file => $output,
            };
         }
      }
      return \@files if @files > 0;
   }

   return $self->log->error("read_next_email_with_attachment: no message ".
      "with an attachment has been found");
}

sub brik_fini {
   my $self = shift;

   # Do your fini here, return 0 on error.

   return $self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Sandbox - remote::sandbox Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
