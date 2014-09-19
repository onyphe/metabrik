#
# $Id: Name.pm 89 2014-09-17 20:29:29Z gomor $
#
# Net::NBName brick
#
package Metabricky::Brick::Netbios::Name;
use strict;
use warnings;

use base qw(Metabricky::Brick);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Net::NBName',
   ];
}

sub help {
   return [
      'run netbios::name nodestatus <ip>',
   ];
}

sub nodestatus {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      return $self->log->info("run netbios::name nodestatus <ip>");
   }

   my $nb = Net::NBName->new;
   if (! $nb) {
      return $self->log->error("can't new() Net::NBName: $!");
   }

   my $ns = $nb->node_status($ip);
   if ($ns) {
      print $ns->as_string;
      return $nb;
   }

   print "no response\n";

   return $nb;
}

1;

__END__
