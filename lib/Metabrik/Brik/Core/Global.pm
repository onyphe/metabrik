#
# $Id$
#
# core::global Brik
#
package Metabrik::Brik::Core::Global;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub properties {
   return {
      revision => '$Revision$',
      tags => [ qw(core main global) ],
      attributes => { 
         input => [ qw(SCALAR) ],
         output => [ qw(SCALAR) ],
         db => [ qw(SCALAR) ],
         file => [ qw(SCALAR) ],
         uri => [ qw(SCALAR) ],
         target => [ qw(SCALAR) ],
         ctimeout => [ qw(SCALAR) ],
         rtimeout => [ qw(SCALAR) ],
         datadir => [ qw(SCALAR) ],
         username => [ qw(SCALAR) ],
         hostname => [ qw(SCALAR) ],
         domainname => [ qw(SCALAR) ],
         homedir => [ qw(SCALAR) ],
         port => [ qw(SCALAR) ],
      },
      attributes_default => {
         input => '/tmp/input.txt',
         output => '/tmp/output.txt',
         db => '/tmp/db.db',
         file => '/tmp/file.txt',
         uri => 'http://www.example.com',
         target => 'localhost',
         ctimeout => 5,
         rtimeout => 5,
         datadir => '/tmp',
         username => $ENV{USER} || 'root',
         hostname => 'localhost',
         domainname => 'example.com',
         homedir => $ENV{HOME} || '/tmp',
         port => 80,
      },
   };
}

1;

__END__
