#
# $Id$
#
# format::lncs Brik
#
package Metabrik::Format::Lncs;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
      },
      commands => {
         install => [ ],  # Inherited
         update => [ ],
         make_dvi => [ qw(input output|OPTIONAL) ],
         make_pdf => [ qw(input output|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         latex => [ ],
         pdflatex => [ ],
      },
      need_packages => {
         ubuntu => [ qw(texlive texlive-lang-french) ],  # Sorry, the author is French
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my $url = 'ftp://ftp.springer.de/pub/tex/latex/llncs/latex2e/llncs.cls';

   return $self->mirror($url, 'llncs.cls');
}

sub make_dvi {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('make_dvi', $input) or return;

   my $datadir = $self->datadir;
   my $llncs = $datadir.'/llncs.cls';

   my $url = 'ftp://ftp.springer.de/pub/tex/latex/llncs/latex2e/llncs.cls';

   my ($base) = $input =~ m{^(.*/).*$};
   if (! defined($base)) {  # Current directory
      my $file = $self->mirror($url, $llncs);
      if (! -f $llncs) {
         return $self->log->error("make_dvi: unable to get [$llncs] file");
      }
      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      $sf->copy($llncs, '.') or return;
   }

   my $cmd = "latex $input";

   return $self->execute($cmd);
}

sub make_pdf {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('make_pdf', $input) or return;

   my $datadir = $self->datadir;
   my $llncs = $datadir.'/llncs.cls';

   my $url = 'ftp://ftp.springer.de/pub/tex/latex/llncs/latex2e/llncs.cls';

   my ($base) = $input =~ m{^(.*/).*$};
   if (! defined($base)) {  # Current directory
      my $file = $self->mirror($url, 'llncs.cls');
      if (! -f $llncs) {
         return $self->log->error("make_pdf: unable to get [$llncs] file");
      }
      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      $sf->copy($llncs, '.') or return;
   }

   my $cmd = "pdflatex $input";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Format::Lncs - format::lncs Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
