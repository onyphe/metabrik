#
# $Id$
#
# server::agent Brik
#
package Metabrik::Server::Agent;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(experimental) ],
      attributes => {
         port => [ qw(integer) ],
      },
      attributes_default => {
         port => 20111,
      },
      commands => {
         listen => [ ],
      },
      require_modules => {
         'Net::Server' => [ ],
      },
   };
}

sub listen {
   my $self = shift;

   my $port = $self->port;

   return Metabrik::Server::Agent::Server->run(
      port => $port,
      ipv => '*',
   );
}

package Metabrik::Server::Agent::Server;
use strict;
use warnings;

use base qw(Net::Server);

sub options {
   my $self     = shift;
   my $prop     = $self->{'server'};
   my $template = shift;

   $self->SUPER::options($template);

   $prop->{'context'} ||= undef;
   $template->{'context'} = \ $prop->{'context'};
}

sub process_request {
   my $self = shift;

   my $context = $self->{server}->{context};
   my $shell = $context->used->{'core::shell'};

   while (<STDIN>) {
      s/[\r\n]+$//;
      $shell->cmd($_);
      last if /^\s*quit\s*$/i;
   }
}

1;

__END__

=head1 NAME

Metabrik::Server::Agent - server::agent Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
