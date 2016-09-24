#
# $Id$
#
# database::cvesearch Brik
#
package Metabrik::Database::Cvesearch;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable cve cpe vfeed circl) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         repo => [ qw(repo) ],
      },
      commands => {
         install => [ ],  # Inherited
         init_database => [ ],
         update_database => [ ],
         repopulate_database => [ ],
      },
      require_modules => {
         'Metabrik::Devel::Git' => [ ],
      },
      require_binaries => {
         python3 => [ ],
         pip3 => [ ],
      },
      need_packages => {
         ubuntu => [ qw(python3 python3-pip mongodb redis-server) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $global = $self->global;
   my $repo = $global->datadir."/devel-git/cve-search";

   return {
      attributes_default => {
         repo => $repo,
      },
   };
}

sub install {
   my $self = shift;

   $self->SUPER::install(@_) or return;

   my $url = 'https://github.com/cve-search/cve-search';

   my $dg = Metabrik::Devel::Git->new_from_brik_init($self) or return;
   my $repo = $dg->clone($url) or return;

   $self->sudo_execute('pip3 install -r '.$repo.'/requirements.txt') or return;

   return 1;
}

sub init_database {
   my $self = shift;

   my $repo = $self->repo;

   for my $this (
      'sbin/db_mgmt.py -p', 'sbin/db_mgmt_cpe_dictionary.py', 'sbin/db_updater.py -c'
   ) {
      my $cmd = $repo.'/'.$this;
      $self->execute($cmd);
   }

   return 1;
}

sub update_database {
   my $self = shift;

   my $repo = $self->repo;

   for my $this ('sbin/db_updater.py -v') {
      my $cmd = $repo.'/'.$this;
      $self->execute($cmd);
   }

   return 1;
}

sub repopulate_database {
   my $self = shift;

   my $repo = $self->repo;

   for my $this ('sbin/db_updater.py -v -f') {
      my $cmd = $repo.'/'.$this;
      $self->execute($cmd);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Database::Cvesearch - database::cvesearch Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
