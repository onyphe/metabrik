#
# $Id$
#
# client::imap Brik
#
package Metabrik::Client::Imap;
use strict;
use warnings;

use base qw(Metabrik::String::Uri);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(imap_uri) ],
         _imap => [ qw(INTERNAL) ],
      },
      commands => {
         open => [ qw(imap_uri|OPTIONAL) ],
         read => [ ],
         read_next => [ ],
         close => [ ],
      },
      require_modules => {
         'Net::IMAP::Simple' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_set_undef_arg('input', $input) or return;

   my $parsed = $self->parse($input) or return;
   my $host = $parsed->{host};
   my $port = $parsed->{port};
   my $user = $parsed->{user};
   my $password = $parsed->{password};

   if (! defined($user) || ! defined($password) || ! defined($host)) {
      return $self->log->error("open: invalid uri [$input] ".
         "missing connection information");
   }

   my $use_ssl = $self->is_imaps_scheme($parsed) ? 1 : 0;

   my $imap = Net::IMAP::Simple->new("$host:$port", use_ssl => $use_ssl);
   if (! defined($imap)) {
      return $self->log->error("open: can't connect to IMAP: $Net::IMAP::Simple::errstr");
   }

   return $self->_imap($imap);
}

1;

__END__

=head1 NAME

Metabrik::Client::Imap - client::imap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
