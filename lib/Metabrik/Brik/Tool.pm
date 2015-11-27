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
         create_tool => [ qw(filename.pl repository|OPTIONAL) ],
         create_brik => [ qw(Brik repository|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
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

sub create_tool {
   my $self = shift;
   my ($filename, $repository) = @_;

   $repository ||= $self->repository;
   if (! defined($filename)) {
      return $self->log->error($self->brik_help_run('create_tool'));
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

# Init your Briks here
# my \$ft = Metabrik::File::Text->new_from_brik_init(\$con) or die("file::text");

# Put your Tool code here
# \$ft->write("test", "/tmp/test.txt");

exit(0);
EOF
;

   return $ft->write($data, $filename);
}

sub create_brik {
   my $self = shift;
   my ($brik, $repository) = @_;

   $repository ||= $self->repository;
   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('create_brik'));
   }

   $brik = lc($brik);
   if ($brik !~ m{^\w+::\w+(::\w+)*$}) {
      return $self->log->error("create_brik: invalid format for Brik [$brik]");
   }

   my @toks = split(/::/, $brik);
   if (@toks < 2) {
      return $self->log->error("create_brik: invalid format for Brik [$brik]");
   }
   for (@toks) {
      $_ = ucfirst($_);
   }
   my $directory;
   if (@toks > 2) {
      $directory = join('/', $repository, @toks[0..$#toks-1]);
   }
   else {
      $directory = join('/', $repository, $toks[0]);
   }
   my $filename = $directory.'/'.$toks[-1].'.pm';
   my $package = join('::', 'Metabrik', @toks);

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($directory) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   my $data =<<EOF
#
# \$Id\$
#
# $brik Brik
#
package $package;
use strict;
use warnings;

use base qw(Metabrik);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '\$Revision\$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
      },
      require_modules => {
      },
      require_binaries => {
      },
      optional_binaries => {
      },
   };
}

sub brik_use_properties {
   my \$self = shift;

   return {
      attributes_default => {
      },
   };
}

sub brik_preinit {
}

sub brik_init {
   my \$self = shift;

   # Do your init here, return 0 on error.

   return \$self->SUPER::brik_init;
}

sub brik_fini {
}

1;

__END__

=head1 NAME

$package - $brik Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
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
