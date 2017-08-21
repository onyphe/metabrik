#
# $Id$
#
# server::kafka Brik
#
package Metabrik::Server::Kafka;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         conf_file => [ qw(file) ],
      },
      attributes_default => {
         conf_file => 'server.properties',
      },
      commands => {
         install => [ ],
         generate_conf => [ ],
         start => [ ],
         stop => [ ],
      },
      require_modules => {
         'Metabrik::Devel::Git' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::System::Service' => [ ],
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
         ubuntu => [ qw(zookeeper zookeeperd gradle openjdk-8-jdk) ],
      },
   };
}

sub install {
   my $self = shift;

   $self->SUPER::install(@_) or return;

   my $datadir = $self->datadir;
   my $url = 'https://github.com/apache/kafka.git';

   my $dg = Metabrik::Devel::Git->new_from_brik_init($self) or return;
   $dg->datadir($datadir);

   my $output_dir = "$datadir/kafka";
   my $repo = $dg->update_or_clone($url, $output_dir) or return;

   #
   # Then build with gradle:
   #
   # cd ~/metabrik/server-kakfa/kafka
   # gradle
   # ./gradlew jar
   #

   return $repo;
}

sub generate_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;
   $self->brik_help_set_undef_arg('generate_conf', $conf_file) or return;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   $conf_file = "$basedir/config/$conf_file";

   my $conf =<<EOF
# The id of the broker. This must be set to a unique integer for each broker.
broker.id=1

# Increase the message size limit
message.max.bytes=20000000
replica.fetch.max.bytes=30000000

log.dirs=$datadir/log
listeners=PLAINTEXT://127.0.0.1:9092

zookeeper.connect=localhost:2181
#zookeeper.connect=192.168.1.101:2181,192.168.1.102:2181,192.168.1.103:2181
EOF
;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);

   $ft->write($conf, $conf_file) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir("$datadir/log") or return;

   return $conf_file;
}

sub start {
   my $self = shift;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";

   my $ss = Metabrik::System::Service->new_from_brik_init($self) or return;
   $ss->start('zookeeper');

   my $cmd = "$basedir/bin/kafka-server-start.sh $basedir/config/server.properties";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Server::Kafka - server::kafka Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
