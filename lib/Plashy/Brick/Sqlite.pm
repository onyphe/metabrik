#
# $Id$
#
# SQLite brick
#
package Plashy::Brick::Sqlite;
use strict;
use warnings;

use base qw(Plashy::Brick);

our @AS = qw(
   db
   dbh
   autocommit
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use DBI;
use DBD::SQLite;

sub help {
   print "set sqlite db <file>\n";
   print "set sqlite autocommit <0|1>\n";
   print "\n";
   print "run sqlite exec <sql>\n";
   print "run sqlite commit\n";
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $db = $self->db;
   if (!defined($db)) {
      $self->inited(0);
      die("set sqlite db <file>\n");
   }

   my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","")
      or die("DBI: $!");

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
      die($self->help);
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
