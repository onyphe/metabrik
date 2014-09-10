#
# $Id$
#
# Agent brick
#
package MetaBricky::Brick::Agent;
use strict;
use warnings;

use base qw(MetaBricky::Brick);

our @AS = qw(
   port
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Server;

sub help {
   print "set agent port <number>\n";
   print "\n";
   print "run agent listen\n";
}

sub default_values {
   return {
      port => 20111,
   };
}

sub listen {
   my $self = shift;

   my $port = $self->port;

   return MetaBricky::Brick::Agent::Server->run(
      port => $port,
      ipv => '*',
      global => $self->global,
   );
}

package MetaBricky::Brick::Agent::Server;
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
   my $meby = $global->meby;

   while (<STDIN>) {
      s/[\r\n]+$//;
      $meby->cmd($_);
      last if /^\s*quit\s*$/i;
   }
}

1;

__END__
