#
# $Id$
#
# database::sqlite Brik
#
package Metabrik::Database::Sqlite;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable database sqlite) ],
      attributes => {
         db => [ qw(sqlite_file) ],
         autocommit => [ qw(0|1) ],
         dbh => [ qw(INTERAL) ],
      },
      attributes_default => {
         autocommit => 1,
      },
      commands => {
         open => [ qw(sqlite_file|OPTIONAL) ],
         exec => [ qw(sql_query) ],
         create => [ qw(table_name fields_array key|OPTIONAL) ],
         insert => [ qw(table_name data_hash) ],
         select => [ qw(table_name data_array key|OPTIONAL) ],
         commit => [ ],
         show_tables => [ ],
         list_types => [ ],
         close => [ ],
      },
      require_modules => {
         'DBI' => [ ],
         'DBD::SQLite' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($db) = @_;

   $db ||= $self->db;
   if (! defined($db)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $dbh = DBI->connect('dbi:SQLite:dbname='.$db,'','');
   if (! $dbh) {
      return $self->log->error("open: DBI: $!");
   }

   $dbh->{AutoCommit} = $self->autocommit;
   $dbh->{RaiseError} = 1;

   $self->dbh($dbh);

   return 1;
}

sub exec {
   my $self = shift;
   my ($sql) = @_;

   if (! defined($sql)) {
      return $self->log->error($self->brik_help_run('exec'));
   }

   my $dbh = $self->dbh;
   if (! defined($dbh)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   $self->debug && $self->log->debug("exec: sql[$sql]");

   my $sth = $dbh->prepare($sql);

   return $sth->execute;
}

sub commit {
   my $self = shift;

   my $dbh = $self->dbh;

   return $dbh->commit;
}

sub create {
   my $self = shift;
   my ($table, $fields, $key) = @_;

   if (! defined($table) && ! defined($fields)) {
      return $self->log->error($self->brik_help_run('create'));
   }

   if (ref($fields) ne 'ARRAY') {
      return $self->log->error("create: Argument 'fields' must be ARRAYREF");
   }

   # create table TABLE (stuffid INTEGER PRIMARY KEY, field1 VARCHAR(512), field2, date DATE);
   # insert into TABLE (field1) values ("value1");

   my $sql = 'CREATE TABLE '.$table.' (';
   for my $field (@$fields) {
      $sql .= $field;
      if (defined($key) && $field eq $key) {
         $sql .= ' PRIMARY KEY NOT NULL';
      }
      $sql .= ',';
   }
   $sql =~ s/,$//;
   $sql .= ');';

   $self->log->verbose("create: $sql");

   return $self->exec($sql);
}

sub insert {
   my $self = shift;
   my ($table, $data) = @_;

   if (! defined($table) && ! defined($data)) {
      return $self->log->error($self->brik_help_run('insert'));
   }

   my $dbh = $self->dbh;
   if (! defined($dbh)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if (ref($data) ne 'HASH') {
      return $self->log->error("insert: Argument 'data' must be HASHREF");
   }

   my $sql = 'INSERT INTO '.$table.' (';
   my @fields = map { $_ } keys %$data;
   my @values = map { "$_" } values %$data;
   $sql .= join(',', @fields);
   $sql .= ') VALUES (';
   for (@values) {
      $sql .= "\"$_\",";
   }
   $sql =~ s/,$//;
   $sql .= ')';

   $self->log->verbose("insert: $sql");

   return $self->exec($sql);
}

sub select {
   my $self = shift;
   my ($table, $data, $key) = @_;

   if (! defined($table) && ! defined($data)) {
      return $self->log->error($self->brik_help_run('select'));
   }

   if (ref($data) ne 'ARRAY') {
      return $self->log->error("select: Argument 'data' must be ARRAYREF");
   }

   if (@$data == 0) {
      return $self->log->error("select: Argument 'data' is empty");
   }

   my $dbh = $self->dbh;
   if (! defined($dbh)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $sql = 'SELECT ';
   for (@$data) {
      $sql .= "$_,";
   }
   $sql =~ s/,$//;
   $sql .= ' FROM '.$table;

   my $sth = $dbh->prepare($sql);
   my $rv = $sth->execute;

   if ($data->[0] eq '*' || ! defined($key)) {
      return $sth->fetchall_arrayref;
   }

   return $sth->fetchall_hashref($key);
}

sub show_tables {
   my $self = shift;

   my $dbh = $self->dbh;
   if (! defined($dbh)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   # $dbh->table_info(undef, $schema, $table, $type, \%attr);
   # $type := 'TABLE', 'VIEW', 'LOCAL TEMPORARY' and 'SYSTEM TABLE'
   my $sth = $dbh->table_info(undef, 'main', '%', 'TABLE');

   my $h = $sth->fetchall_arrayref;
   my @r = ();
   for my $this (@$h) {
      push @r, $this->[-1];  # Last entry is the CREATE TABLE one.
   }

   return \@r;
}

sub list_types {
   my $self = shift;

   return [
      'INTEGER',
      'DATE',
      'VARCHAR(int)',
   ];
}

sub close {
   my $self = shift;

   my $dbh = $self->dbh;
   if (defined($dbh)) {
      $dbh->commit;
      $dbh->disconnect;
      $self->dbh(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Database::Sqlite - database::sqlite Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
