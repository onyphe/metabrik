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
      tags => [ qw(unstable jail) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         name => [ qw(name) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         email => [ qw(email) ],
         force => [ qw(0|1) ],
      },
      attributes_default => {
         force => 1,
      },
      commands => {
         install => [ ],
         build => [ qw(name directory) ],
         search => [ qw(name) ],
         get_image_id => [ qw(name) ],
         list => [ ],
         start => [ qw(name|$name_list) ],
         stop => [ qw(name|$name_list) ],
         restart => [ qw(name|$name_list) ],
         create => [ qw(name ip_address) ],
         backup => [ qw(name|$name_list) ],
         restore => [ qw(name ip_address archive_tar_gz) ],
         delete => [ qw(name) ],
         update => [ ],
         exec => [ qw(name command) ],
         console => [ qw(name) ],
         login => [ qw(email|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         push => [ qw(name) ],
         tag => [ qw(id tag) ],
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

   return $self->execute("wget -qO- https://get.docker.com/ | sh");
}

sub build {
   my $self = shift;
   my ($name, $directory) = @_;

   $self->brik_help_run_undef_arg('build', $name) or return;
   $self->brik_help_run_undef_arg('build', $directory) or return;
   $self->brik_help_run_directory_not_found('build', $directory) or return;

   my $cmd = "docker build -t $name $directory";

   return $self->execute($cmd);
}

sub search {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('search'));
   }

   my $cmd = "docker search $jail_name";

   return $self->execute($cmd);
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

sub get_image_id {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('get_image_id', $name) or return;

   my $lines = $self->list or return;
   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);
      if ($toks[0] eq $name) {
         return $toks[2];
      }
   }

   return 'undef';
}

sub list {
   my $self = shift;

   my $cmd = "docker images";

   return $self->capture($cmd);
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('stop', $name) or return;

   my $cmd = "docker stop $name";

   return $self->execute($cmd);
}

sub start {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $cmd = "";

   return $self->execute($cmd);
}

sub restart {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('restart'));
   }

   my $cmd = "";

   return $self->execute($cmd);
}

sub create {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('create'));
   }

   my $cmd = "docker pull $jail_name";

   return $self->execute($cmd);
}

sub backup {
   my $self = shift;
   my ($jail_name) = @_;

   if (! defined($jail_name)) {
      return $self->log->error($self->brik_help_run('backup'));
   }

   my $cmd = "";

   return $self->execute($cmd);
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

   return $self->execute($cmd);
}

sub delete {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('delete', $name) or return;

   my $cmd = "docker rmi -f $name";

   return $self->execute($cmd);
}

sub update {
   my $self = shift;

   # XXX: needed?

   return 1;
}

sub console {
   my $self = shift;
   my ($name, $shell) = @_;

   $shell ||= '/bin/bash';
   $self->brik_help_run_undef_arg('console', $name) or return;

   my $cmd = "docker run -it $name '$shell'";

   return $self->execute($cmd);
}

sub login {
   my $self = shift;
   my ($email, $username, $password) = @_;

   $email ||= $self->email;
   $username ||= $self->username;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('login', $email) or return;
   $self->brik_help_run_undef_arg('login', $username) or return;

   my $cmd = "docker login --username=$username --email=$email";
   if ($password) {
      $cmd .= " --password=$password";
   }

   return $self->execute($cmd);
}

sub push {
   my $self = shift;
   my ($name) = @_;

   $name ||= $self->name;
   $self->brik_help_run_undef_arg('push', $name) or return;

   my $cmd = "docker push $name";

   return $self->execute($cmd);
}

sub tag {
   my $self = shift;
   my ($id, $tag) = @_;

   $self->brik_help_run_undef_arg('tag', $id) or return;
   $self->brik_help_run_undef_arg('tag', $tag) or return;

   my $cmd = "docker tag $id $tag";

   return $self->execute($cmd);
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
