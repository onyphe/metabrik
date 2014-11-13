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
         db => [ qw(sqlite_db) ],
         dbh => [ qw(db_handler) ],
         autocommit => [ qw(0|1) ],
      },
      commands => {
         exec => [ qw(sql_query) ],
         commit => [ ],
      },
      require_modules => {
         'DBI' => [ ],
         'DBD::SQLite' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift->SUPER::brik_init(
      @_,
   ) or return 1; # Init already done

   my $db = $self->db;
   if (! defined($db)) {
      $self->inited(0);
      return $self->log->error($self->brik_help_set('db'));
   }

   my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","")
      or return $self->log->error("DBI: $!");

   $dbh->{AutoCommit} = 0;
   if (defined($self->autocommit)) {
      $dbh->{AutoCommit} = $self->autocommit;
   }

   $self->dbh($dbh);

   return $self;
}

sub exec {
   my $self = shift;
   my ($sql) = @_;

   if (! defined($sql)) {
      return $self->log->error($self->brik_help_run('exec'));
   }

   my $dbh = $self->dbh;

   $self->debug && $self->log->debug("exec: sql[$sql]");

   my $sth = $dbh->prepare($sql);

   return $sth->execute;
}

sub commit {
   my $self = shift;

   my $dbh = $self->dbh;

   return $dbh->commit;
}

1;

__END__
