#
# $Id$
#
# string::password Brik
#
package Metabrik::String::Password;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable password random) ],
      attributes => {
         charset => [ qw($character_list) ],
         length => [ qw(integer) ],
         count => [ qw(integer) ],
      },
      attributes_default => {
         charset => [ 'A'..'K', 'M'..'Z', 'a'..'k', 'm'..'z', 2..9, '_', '-', '#', '!' ],
         length => 10,
         count => 5,
      },
      commands => {
         generate => [ ],
      },
      require_modules => {
         'String::Random' => [ ],
      },
   };
}

sub generate {
   my $self = shift;

   my $charset = $self->charset;
   my $length = $self->length;
   my $count = $self->count;

   my $rand = String::Random->new;
   $rand->{A} = $charset;

   my @passwords = ();
   for (1..$count) {
      push @passwords, $rand->randpattern("A"x$length);
   }

   return \@passwords;
}

1;

__END__
