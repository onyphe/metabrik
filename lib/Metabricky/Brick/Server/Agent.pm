#
# $Id: Agent.pm 89 2014-09-17 20:29:29Z gomor $
#
# Agent brick
#
package Metabricky::Brick::Server::Agent;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   port
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Net::Server',
   ];
}

sub help {
   return [
      'set server::agent port <number>',
      'run server::agent listen',
   ];
}

sub default_values {
   return {
      port => 20111,
   };
}

sub listen {
   my $self = shift;

   my $port = $self->port;

   return Metabricky::Brick::Server::Agent::Server->run(
      port => $port,
      ipv => '*',
      bricks => $self->bricks,
   );
}

package Metabricky::Brick::Server::Agent::Server;
use strict;
use warnings;

use base qw(Net::Server);

sub options {
   my $self     = shift;
   my $prop     = $self->{'server'};
   my $template = shift;

   $self->SUPER::options($template);

   $prop->{'bricks'} ||= undef;
   $template->{'bricks'} = \ $prop->{'bricks'};
}

sub process_request {
   my $self = shift;

   my $bricks = $self->{server}->{bricks};
   my $meby = $bricks->{'shell::meby'};

   while (<STDIN>) {
      s/[\r\n]+$//;
      $meby->cmd($_);
      last if /^\s*quit\s*$/i;
   }
}

1;

__END__
