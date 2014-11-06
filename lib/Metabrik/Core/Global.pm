#
# $Id$
#
# core::global Brik
#
package Metabrik::Core::Global;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(core main global) ],
      attributes => { 
         device => [ qw(device) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
         db => [ qw(db) ],
         file => [ qw(file) ],
         uri => [ qw(uri) ],
         target => [ qw(target) ],
         family => [ qw(ipv4|ipv6) ],
         protocol => [ qw(udp|tcp) ],
         ctimeout => [ qw(seconds) ],
         rtimeout => [ qw(seconds) ],
         datadir => [ qw(directory) ],
         username => [ qw(username) ],
         hostname => [ qw(hostname) ],
         domainname => [ qw(domainname) ],
         homedir => [ qw(directory) ],
         port => [ qw(port) ],
         encoding => [ qw(utf8|ascii) ],
         auto_use_on_require => [ qw(0|1) ],
         auto_install_on_require => [ qw(0|1) ],
      },
      attributes_default => {
         device => 'eth0',
         input => '/tmp/input.txt',
         output => '/tmp/output.txt',
         db => '/tmp/db.db',
         file => '/tmp/file.txt',
         uri => 'http://www.example.com',
         target => 'localhost',
         family => 'ipv4',
         protocol => 'tcp',
         ctimeout => 5,
         rtimeout => 5,
         datadir => '/tmp',
         username => $ENV{USER} || 'root',
         hostname => 'localhost',
         domainname => 'example.com',
         homedir => $ENV{HOME} || '/tmp',
         port => 80,
         encoding => 'utf8',
         auto_use_on_require => 1,
         auto_install_on_require => 0,
      },
      commands => {
         sleep => [ ],
      },
   };
}

sub sleep {
   my $self = shift;

   sleep(5);

   return 1;
}

1;

__END__
