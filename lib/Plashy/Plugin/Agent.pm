#
# Agent plugin
#
package Plashy::Plugin::Agent;
use strict;
use warnings;

use base qw(Plashy::Plugin);

our @AS = qw(
   port
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Server;

sub new {
   my $self = shift->SUPER::new(
      port => 20111,
      @_,
   );

   return $self;
}

sub help {
   print "set agent port <number>\n";
   print "\n";
   print "run agent listen\n";
}

sub listen {
   my $self = shift;

   my $port = $self->port;

   return Plashy::Plugin::Agent::Server->run(
      port => $port,
      ipv => '*',
      global => $self->global,
   );
}

package Plashy::Plugin::Agent::Server;
use strict;
use warnings;

use base qw(Net::Server);

sub options {
   my $self     = shift;
   my $prop     = $self->{'server'};
   my $template = shift;

   $self->SUPER::options($template);

   $prop->{'global'} ||= undef;
   $template->{'global'} = \ $prop->{'global'};
}

sub process_request {
   my $self = shift;

   my $global = $self->{server}->{global};
   my $plashy = $global->plashy;

   while (<STDIN>) {
      s/[\r\n]+$//;
      $plashy->cmd($_);
      last if /^\s*quit\s*$/i;
   }
}

1;

__END__
