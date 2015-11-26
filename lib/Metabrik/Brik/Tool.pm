#
# $Id$
#
# brik::tool Brik
#
package Metabrik::Brik::Tool;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable program) ],
      attributes => {
         repository => [ qw(repository) ],
      },
      commands => {
         initialize => [ qw(filename.pl repository|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         repository => $self->global->repository,
      },
   };
}

sub initialize {
   my $self = shift;
   my ($filename, $repository) = @_;

   $repository ||= $self->repository;
   if (! defined($filename)) {
      return $self->log->error($self->brik_help_run('initialize'));
   }

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   my $data =<<EOF
#!/usr/bin/perl
#
# \$Id\$
#
use strict;
use warnings;

use lib qw($repository);

use Data::Dumper;
use Metabrik::Core::Context;

# Put your Briks here

my \$con = Metabrik::Core::Context->new or die("core::context");

# Put your Tool code here

exit(0);
EOF
;

   return $ft->write($data, $filename);
}

1;

__END__

=head1 NAME

Metabrik::Brik::Tool - brik::tool Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
