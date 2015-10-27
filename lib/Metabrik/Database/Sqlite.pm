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
         dbh => [ qw(INTERNAL) ],
      },
      attributes_default => {
         autocommit => 1,
      },
      commands => {
         open => [ qw(sqlite_file|OPTIONAL) ],
         exec => [ qw(sql_query) ],
         create => [ qw(table_name fields_array key|OPTIONAL) ],
         insert => [ qw(table_name data_hash) ],
         select => [ qw(table_name fields_array|OPTIONAL key|OPTIONAL) ],
         commit => [ ],
         show_tables => [ ],
         describe_table => [ ],
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

   my $dbh = DBI->connect('dbi:SQLite:dbname='.$db,'','', {
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

   if ($self->autocommit) {
      $self->log->verbose("commit: skipping cause autocommit is on");
      return 1;
   }

   eval {
      $dbh->commit;
   };
   if ($@) {
      chomp($@);
      return $self->log->warning("commit: $@");
   }

   return 1;
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
      # Fields are table fields, we normalize them (space char not allowed)
      $field =~ s/ /_/g;
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

   my @data = ();
   if (ref($data) eq 'ARRAY') {
      for my $this (@$data) {
         if (ref($this) ne 'HASH') {
            $self->log->verbose('insert: not a hash, skipping');
            next;
         }
         push @data, $this;
      }
   }
   else {
      if (ref($data) ne 'HASH') {
         return $self->log->error("insert: Argument 'data' must be HASHREF");
      }
      push @data, $data;
   }

   for my $this (@data) {
      my $sql = 'INSERT INTO '.$table.' (';
      # Fields are table fields, we normalize them (space char not allowed)
      my @fields = map { s/ /_/g; $_ } keys %$this;
      my @values = map { $_ } values %$this;
      $sql .= join(',', @fields);
      $sql .= ') VALUES (';
      for (@values) {
         $sql .= "\"$_\",";
      }
      $sql =~ s/,$//;
      $sql .= ')';

      $self->log->verbose("insert: $sql");

      $self->exec($sql);
   }

   return 1;
}

sub select {
   my $self = shift;
   my ($table, $fields, $key) = @_;

   $fields ||= [ '*' ];

   if (! defined($table)) {
      return $self->log->error($self->brik_help_run('select'));
   }

   if (ref($fields) ne 'ARRAY') {
      return $self->log->error("select: Argument 'fields' must be ARRAYREF");
   }

   if (@$fields == 0) {
      return $self->log->error("select: Argument 'fields' is empty");
   }

   my $dbh = $self->dbh;
   if (! defined($dbh)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $sql = 'SELECT ';
   for (@$fields) {
      # Fields are table fields, we normalize them (space char not allowed)
      s/ /_/g;
      $sql .= "$_,";
   }
   $sql =~ s/,$//;
   $sql .= ' FROM '.$table;

   my $sth = $dbh->prepare($sql);
   my $rv = $sth->execute;

   if (! defined($key)) {
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

# https://metacpan.org/pod/DBI#table_info
sub describe_table {
#my $sth = $dbh->column_info(undef,'table_name',undef,undef);
#$sth->fetchall_arrayref;
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
