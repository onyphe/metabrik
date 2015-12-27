#
# $Id$
#
# devel::subversion Brik
#
package Metabrik::Devel::Subversion;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      commands => {
         checkout => [ qw(repository directory|OPTIONAL) ],
         clone => [ qw(repository directory|OPTIONAL) ],
      },
      require_binaries => {
         'svn' => [ ],
      },
      need_packages => {
         'ubuntu' => [ qw(subversion) ],
      },
   };
}

sub checkout {
   my $self = shift;
   my ($repository, $directory) = @_;

   $directory ||= '';
   $self->brik_help_run_undef_arg('checkout', $repository) or return;

   my $cmd = "svn co $repository $directory";
   return $self->execute($cmd);
}

# alias to checkout
sub clone {
   my $self = shift;

   return $self->checkout(@_);
}

1;

__END__

=head1 NAME

Metabrik::Devel::Subversion - devel::subversion Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
