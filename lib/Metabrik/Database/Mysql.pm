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
         save => [ qw(db_name output_file) ],
         load => [ qw(input_file db_name) ],
         createdb => [ qw(db_name) ],
         dropdb => [ qw(db_name) ],
         create_user => [ qw(username password|OPTIONAL) ],
         grant_all_privileges => [ qw(database username ip_address|OPTIONAL) ],
         password_prompt => [ qw(string|OPTIONAL) ],
         enter_shell => [ qw(db_name|OPTIONAL host|OPTIONAL port|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
      },
      require_modules => {
         'DBI' => [ ],
         'DBD::mysql' => [ ],
         'Metabrik::String::Password' => [ ],
      },
      require_binaries => {
         'mysql' => [ ],
         'mysqladmin' => [ ],
      },
   };
}

sub password_prompt {
   my $self = shift;
   my ($string) = @_;

   my $sp = Metabrik::String::Password->new_from_brik_init($self) or return;
   return $sp->prompt($string);
}

sub open {
   my $self = shift;
   my ($db, $host, $port, $username, $password) = @_;

   $db ||= $self->db;
   $host ||= $self->host;
   $port ||= $self->port;
   $username ||= $self->username;
   $password ||= $self->password || $self->password_prompt("Enter $username password: ") or return;

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

   if (! defined($db)) {
      return $self->log->error($self->brik_help_run('createdb'));
   }

   my $host = $self->host;
   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password || $self->password_prompt("Enter $username password: ") or return;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   # mysqladmin create database
   return $sc->system("mysqladmin -h $host --port=$port -u $username --password=$password create $db");
}

sub dropdb {
   my $self = shift;
   my ($db) = @_;

   if (! defined($db)) {
      return $self->log->error($self->brik_help_run('dropdb'));
   }

   my $host = $self->host;
   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password || $self->password_prompt("Enter $username password: ") or return;

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
   my $password = $self->password || $self->password_prompt("Enter $username password: ") or return;

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
   my $password = $self->password || $self->password_prompt("Enter $username password: ") or return;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   # mysql -h hostname -u user --password=password databasename < filename
   return $sc->system("mysql -h $host --port=$port -u $username --password=$password $db < $filename");
}

sub create_user {
   my $self = shift;
   my ($username, $password, $ip) = @_;

   $ip ||= '%';
   if (! defined($username)) {
      return $self->log->error($self->brik_help_run('create_user'));
   }

   my $mysql_host = $self->host;
   my $mysql_port = $self->port;
   my $mysql_username = $self->username;
   my $mysql_password = $self->password || $self->password_prompt("Enter $mysql_username password: ") or return;

   $password ||= $self->password_prompt("Enter $username password: ") or return;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   my $cmd = "mysql -h $mysql_host --port=$mysql_port -u $mysql_username --password=$mysql_password --execute=\"create user $username\@'$ip' identified by '$password'\" mysql";

   $self->debug && $self->log->debug("create_user: cmd [$cmd]");

   return $sc->system($cmd);
}

sub grant_all_privileges {
   my $self = shift;
   my ($db, $username, $ip) = @_;

   $ip ||= '%';
   if (! defined($db)) {
      return $self->log->error($self->brik_help_run('grant_all_privileges'));
   }
   if (! defined($username)) {
      return $self->log->error($self->brik_help_run('grant_all_privileges'));
   }

   my $mysql_host = $self->host;
   my $mysql_port = $self->port;
   my $mysql_username = $self->username;
   my $mysql_password = $self->password || $self->password_prompt("Enter $mysql_username password: ") or return;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   my $cmd = "mysql -h $mysql_host --port=$mysql_port -u $mysql_username --password=$mysql_password --execute=\"grant all privileges on $db.* to $username\@'$ip'\" mysql";

   $self->debug && $self->log->debug("grant_all_privileges: cmd [$cmd]");

   return $sc->system($cmd);
}

sub enter_shell {
   my $self = shift;
   my ($mysql_db, $mysql_host, $mysql_port, $mysql_username, $mysql_password) = @_;

   $mysql_db ||= $self->db;
   $mysql_host ||= $self->host;
   $mysql_port ||= $self->port;
   $mysql_username ||= $self->username;
   $mysql_password ||= $self->password || $self->password_prompt("Enter $mysql_username password: ") or return;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   my $cmd = "mysql -h $mysql_host --port=$mysql_port -u $mysql_username --password=$mysql_password mysql";

   $self->debug && $self->log->debug("shell: cmd [$cmd]");

   return $sc->system($cmd);
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
