#
# $Id$
#
# database::mysql Brik
#
package Metabrik::Database::Mysql;
use strict;
use warnings;

use base qw(Metabrik::Database::Sqlite);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable database mysql) ],
      attributes => {
         db => [ qw(db_name) ],
         autocommit => [ qw(0|1) ],
         host => [ qw(host) ],
         port => [ qw(port) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         dbh => [ qw(INTERNAL) ],
      },
      attributes_default => {
         autocommit => 1,
         db => 'mysql',
         host => 'localhost',
         port => 3306,
         username => 'root',
         password => '',
      },
      commands => {
         open => [ qw(db_name|OPTIONAL host|OPTIONAL port|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         exec => [ qw(sql_query) ],
         create => [ qw(table_name fields_array key|OPTIONAL) ],
         insert => [ qw(table_name data_hash) ],
         select => [ qw(table_name fields_array|OPTIONAL key|OPTIONAL) ],
         commit => [ ],
         show_tables => [ ],
         list_types => [ ],
         close => [ ],
         save => [ qw(db output_file) ],
         load => [ qw(input_file db) ],
         createdb => [ qw(db) ],
         dropdb => [ qw(db) ],
      },
      require_modules => {
         'DBI' => [ ],
         'DBD::mysql' => [ ],
      },
      require_binaries => {
         'mysql' => [ ],
         'mysqladmin' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($db, $host, $port, $username, $password) = @_;

   $db ||= $self->db;
   $host ||= $self->host;
   $port ||= $self->port;
   $username ||= $self->username;
   $password ||= $self->password;

   my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host;port=$port", $username, $password, {
      AutoCommit => $self->autocommit,
      RaiseError => 1,
      PrintError => 0,
      PrintWarn => 0,
      #HandleError => sub {
         #my ($errstr, $dbh, $arg) = @_;
         #die("DBI: $errstr\n");
      #},
   });
   if (! $dbh) {
      return $self->log->error("open: DBI: $DBI::errstr");
   }

   $self->dbh($dbh);

   return 1;
}

sub show_tables {
   my $self = shift;

   my $dbh = $self->dbh;
   if (! defined($dbh)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my @tables = map { s/.*\.//; s/`//g; $_ } $dbh->tables;

   return \@tables;
}

sub createdb {
   my $self = shift;
   my ($db) = @_;

   my $host = $self->host;
   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   # mysqladmin create database
   return $sc->system("mysqladmin -h $host --port=$port -u $username --password=$password create $db");
}

sub dropdb {
   my $self = shift;
   my ($db) = @_;

   my $host = $self->host;
   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   # mysqladmin drop database
   return $sc->system("mysqladmin -h $host --port=$port -u $username --password=$password drop $db");
}

sub save {
   my $self = shift;
   my ($db, $filename) = @_;

   if (! defined($db)) {
      return $self->log->error($self->brik_help_run('save'));
   }
   if (! defined($filename)) {
      return $self->log->error($self->brik_help_run('save'));
   }

   my $host = $self->host;
   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   # mysqldump -h hostname -u user --password=password databasename > filename
   return $sc->system("mysqldump -h $host --port=$port -u $username --password=$password $db > $filename");
}

sub load {
   my $self = shift;
   my ($filename, $db) = @_;

   if (! defined($filename)) {
      return $self->log->error($self->brik_help_run('load'));
   }
   if (! -f $filename) {
      return $self->log->error("load: file [$filename] not found");
   }
   if (! defined($db)) {
      return $self->log->error($self->brik_help_run('load'));
   }

   my $host = $self->host;
   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   # mysql -h hostname -u user --password=password databasename < filename
   return $sc->system("mysql -h $host --port=$port -u $username --password=$password $db < $filename");
}

1;

__END__

=head1 NAME

Metabrik::Database::Mysql - database::mysql Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
