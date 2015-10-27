#
# $Id$
#
# file::ole Brik
#
package Metabrik::File::Ole;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable file ole read) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         olevba => [ qw(olevba.py) ],
      },
      attributes_default => {
         olevba => '/usr/local/lib/python2.7/dist-packages/oletools/olevba.py',
      },
      commands => {
         install => [ ],
         extract_vbs => [ qw(input|OPTIONAL output|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::Os' => [ ],
         'Metabrik::System::Package' => [ ],
         'Metabrik::File::Text' => [ ],
      },
      require_binaries => {
         'python' => [ ],
      },
   };
}

sub install {
   my $self = shift;

   my $so = Metabrik::System::Os->new_from_brik_init($self) or return;
   my $distrib = $so->distribution or return;
   my $os = $distrib->{name};

   if ($os eq 'Ubuntu') {
      my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
      $sp->install('python-pip') or return;

      my $prev = $self->use_sudo;
      $self->use_sudo(1);
      $self->system('pip install oletools --upgrade');
      $self->use_sudo($prev);
   }
   else {
      return $self->log->error("install: OS [$os] not supported for install Command");
   }

   return 1;
}

sub extract_vbs {
   my $self = shift;
   my ($input, $output) = @_;

   $input ||= $self->input;
   $output ||= $self->output;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('extract_vbs'));
   }
   if (! defined($output)) {
      return $self->log->error($self->brik_help_run('extract_vbs'));
   }

   my $olevba = $self->olevba;
   if (! -f $olevba) {
      return $self->log->error("extract_vbs: olevba.py not found at [$olevba]");
   }

   my $out = $self->capture("python $olevba $input");

   #for (@$out) { print "LINE[$_]\n"; }

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->write($out, $output) or return;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Ole - file::ole Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
