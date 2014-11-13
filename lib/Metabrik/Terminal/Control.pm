#
# $Id$
#
# terminal::control Brik
#
package Metabrik::Terminal::Control;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable terminal) ],
      commands => {
         title => [ qw(string) ],
      },
   };
}

sub title {
   my $self = shift;
   my ($title) = @_;

   if (! defined($title)) {
      return $self->log->error($self->brik_help_run('title'));
   }

   print "\c[];$title\a\e[0m";

   return $title;
}

1;

__END__
