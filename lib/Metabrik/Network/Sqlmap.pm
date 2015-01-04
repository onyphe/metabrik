#
# $Id$
#
# network::sqlmap Brik
#
package Metabrik::Network::Sqlmap;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network security scanner sqlmap sql injection) ],
      attributes => {
         cookie => [ qw(string) ],
         parameter => [ qw(parameter_name) ],
         request_file => [ qw(file) ],
         args => [ qw(sqlmap_arguments) ],
         output_file => [ qw(file) ],
      },
      commands => {
         start => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         request_file => $self->global->datadir.'/sqlmap_request.txt',
         parameter => 'parameter',
         args => '--ignore-proxy -v 3 --level=5 --risk=3 --user-agent "Mozilla"',
      },
   };
}

# python /usr/share/sqlmap-dev/sqlmap.py -p PARAMETER -r /root/XXX/outil_sqlmap/request.raw --ignore-proxy -v 3 --level=5 --risk=3 --user-agent "Mozilla" 2>&1 | tee /root/XXX/outil_sqlmap/XXX.txt
sub start {
   my $self = shift;

   my $args = $self->args;
   my $cookie = $self->cookie;
   my $parameter = $self->parameter;
   my $request_file = $self->request_file;
   my $output_file = $self->output_file;

   if (! -f $request_file) {
      return $self->log->error("start: request file [$request_file] not found");
   }

   my $cmd = "sqlmap -p $parameter $args -r $request_file";
   if (defined($output_file)) {
      $cmd .= ' 2>&1 | tee '.$output_file;
   }

   system($cmd);

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Sqlmap - network::sqlmap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
