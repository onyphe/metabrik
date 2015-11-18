#
# $Id$
#
# system::docker Brik
#
package Metabrik::System::Docker;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable system jail docker) ],
      commands => {
         install => [ ],
         build => [ qw(jail_name directory) ],
         search => [ qw(jail_name) ],
         list => [ ],
         start => [ qw(jail_name|$jail_list) ],
         stop => [ qw(jail_name|$jail_list) ],
         restart => [ qw(jail_name|$jail_list) ],
         create => [ qw(jail_name ip_address) ],
         backup => [ qw(jail_name|$jail_list) ],
         restore => [ qw(jail_name ip_address archive_tar_gz) ],
         delete => [ qw(jail_name) ],
         update => [ ],
         exec => [ qw(jail_name command) ],
         console => [ qw(jail_name) ],
      },
      # Have to be optional because of install Command
      optional_binaries => {
         'docker' => [ ],
      },
      require_binaries => {
         'wget' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   if (! $self->brik_has_binary("docker")) {
      $self->log->warning("brik_init: you have to execute install Command now");
   }

   return $self->SUPER::brik_init;
}

sub install {
   my $self = shift;

   return $self->system("wget -qO- https://get.docker.com/ | sh");
}

sub build {
   my $self = shift;
   my ($jail_name, $directory) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('build'));
   }
   if (! defined($directory)) {
      return $self->log->error($self->brik_help_run('build'));
   }

   my $cmd = "docker build -t $jail_name $directory";

   return $self->system($cmd);
}

sub search {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('search'));
   }

   my $cmd = "docker search $jail_name";

   return $self->system($cmd);
}

sub exec {
   my $self = shift;
   my ($jail_name, $exec) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('exec'));
   }
   if (! defined($exec)) {
      return $self->log->error($self->brik_help_run('exec'));
   }

   return $self->console($jail_name, $exec);
}

sub list {
   my $self = shift;

   my $cmd = "docker images";

   return $self->system($cmd);
}

sub stop {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('stop'));
   }

   my $cmd = "";

   return $self->system($cmd);
}

sub start {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $cmd = "";

   return $self->system($cmd);
}

sub restart {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('restart'));
   }

   my $cmd = "";

   return $self->system($cmd);
}

sub create {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('create'));
   }

   my $cmd = "";

   return $self->system($cmd);
}

sub backup {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('backup'));
   }

   my $cmd = "";

   return $self->system($cmd);
}

sub restore {
   my $self = shift;
   my ($jail_name, $archive_tar_gz) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('restore'));
   }
   if (! defined($archive_tar_gz)) {
      return $self->log->error($self->brik_help_run('restore'));
   }
      
   my $cmd = "";

   return $self->system($cmd);
}

sub delete {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('delete'));
   }

   my $cmd = "";

   return $self->system($cmd);
}

sub update {
   my $self = shift;

   # XXX: needed?

   return 1;
}

sub console {
   my $self = shift;
   my ($jail_name, $shell) = @_;

   $shell ||= '/bin/bash';
   my $cmd = "docker run -it $jail_name '$shell'";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Docker - system::docker Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
