#
# $Id$
#
# server::agent Brik
#
package Metabrik::Brik::Server::Agent;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      port => [],
   };
}

sub require_modules {
   return {
      'Net::Server' => [],
   };
}

sub help {
   return {
      'set:port' => '<number>',
      'run:listen' => '',
   };
}

sub default_values {
   return {
      port => 20111,
   };
}

sub listen {
   my $self = shift;

   my $port = $self->port;

   return Metabrik::Brik::Server::Agent::Server->run(
      port => $port,
      ipv => '*',
   );
}

package Metabrik::Brik::Server::Agent::Server;
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
   my $meby = $context->loaded->{'shell::meby'};

   while (<STDIN>) {
      s/[\r\n]+$//;
      $meby->cmd($_);
      last if /^\s*quit\s*$/i;
   }
}

1;

__END__
