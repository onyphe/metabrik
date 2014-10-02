#
# $Id$
#
# database::sqlite Brik
#
package Metabrik::Brik::Database::Sqlite;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      db => [],
      dbh => [],
      autocommit => [],
   };
}

sub require_modules {
   return {
      'DBI' => [],
      'DBD::SQLite' => [],
   };
}

sub help {
   return {
      'set:db' => '<file>',
      'set:autocommit' => '<0|1>',
      'run:exec' => '<sql>',
      'run:commit' => '',
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $db = $self->db;
   if (! defined($db)) {
      $self->inited(0);
      return $self->log->info($self->help_set('db'));
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
      return $self->log->info($self->help_run('exec'));
   }

   my $dbh = $self->dbh;

   print "DEBUG[$sql]\n";

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
