#
# $Id$
#
# client::dns Brik
#
package Metabrik::Client::Dns;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable client dns) ],
      commands => {
         a_lookup => [ qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
         ptr_lookup => [ qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
         mx_lookup => [ qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
         ns_lookup => [  qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
         cname_lookup => [  qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
         soa_lookup => [  qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
         srv_lookup => [  qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
         txt_lookup => [  qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL) ],
      },
      attributes => {
         nameserver => [ qw(ip_address|$ip_address_list) ],
         timeout => [ qw(0|1) ],
         rtimeout => [ qw(timeout) ],
         return_list => [ qw(0|1) ],
      },
      attributes_default => {
         timeout => 0,
         rtimeout => 2,
         return_list => 1,
      },
      require_modules => {
         'Net::Nslookup' => [ ],
      },
   };
}

sub _nslookup {
   my $self = shift;
   my ($host, $type, $nameserver) = @_;

   my %args = (
      type => $type,
      timeout => $self->rtimeout,
   );
   if (defined($nameserver)) {
      $args{server} = $nameserver;  # Accepts a string or an arrayref
   }

   # Reset timeout indicator
   $self->timeout(0);

   my @r;
   eval {
      @r = Net::Nslookup::nslookup(host => $host, %args);
   };
   if ($@ && $@ ne "alarm\n") {
      chomp($@);
      return $self->log->error("nslookup: failed for host [$host] with type [$type]: $@");
   }
   elsif ($@ && $@ eq "alarm\n") {
      $self->timeout(1);
      $self->log->info("nslookup: timeout waiting response for host [$host] with type [$type]");
   }
   elsif (@r == 0) {
      $self->log->info("nslookup: no response for host [$host] with type [$type]");
   }

   return \@r;
}

sub _resolve {
   my $self = shift;
   my ($ip, $type, $nameserver) = @_;

   if (ref($ip) eq 'ARRAY') {
      my %results = ();
      for my $host (@$ip) {
         my $r = $self->_nslookup($host, $type, $nameserver) 
            or next;
         if ($self->return_list) {
            $results{$host} = $r;
         }
         else {
            $results{$host} = $r->[0];
         }
      }

      return \%results;
   }
   elsif (! ref($ip)) {
      my $r = $self->_nslookup($ip, $type, $nameserver)
         or return;
      if ($self->return_list) {
         return $r;
      }
      else {
         return $r->[0];
      }
   }
   else {
      return $self->log->error("resolve: don't know how to resolve host [$ip]");
   }

   return;
}

sub a_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('a_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'A', $nameserver);
}

sub ptr_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('ptr_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'PTR', $nameserver);
}

sub mx_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('mx_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'MX', $nameserver);
}

sub ns_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('ns_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'NS', $nameserver);
}

sub soa_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('soa_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'SOA', $nameserver);
}

sub txt_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('txt_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'TXT', $nameserver);
}

sub srv_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('srv_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'SRV', $nameserver);
}

sub cname_lookup {
   my $self = shift;
   my ($ip_address, $nameserver) = @_;

   if (! defined($ip_address)) {
      return $self->log->error($self->brik_help_run('cname_lookup'));
   }

   $nameserver ||= $self->nameserver;

   return $self->_resolve($ip_address, 'CNAME', $nameserver);
}

1;

__END__

=head1 NAME

Metabrik::Client::Dns - client::dns Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
