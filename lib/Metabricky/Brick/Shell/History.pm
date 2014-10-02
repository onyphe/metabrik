#
# $Id: Template.pm 89 2014-09-17 20:29:29Z gomor $
#
# shell::history Brick
#
package Metabricky::Brick::Shell::History;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   shell
   history_file
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub help {
   return {
      'set:history_file' => '<file>',
      'run:load' => '',
      'run:write' => '',
      'run:get' => '',
      'run:get_one' => '<number>',
      'run:get_range' => '<number1..number2>',
   };
}

sub default_values {
   my $self = shift;

   return {
      history_file => $self->global->homedir.'/.meby_history',
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $shell = $self->shell;

   if (! defined($shell)) {
      return $self->log->error("init: you must give a shell Brick as Attribute");
   }

   return $self;
}

sub load {
   my $self = shift;

   my $shell = $self->shell;
   my $history_file = $self->history_file;

   if (! defined($shell)) {
      return $self->log->error("load: you must give a shell Brick as Attribute");
   }

   if ($shell->term->can('ReadHistory')) {
      if (! -f $history_file) {
         return $self->log->error("load: can't find history file [$history_file]");
      }

      $shell->term->ReadHistory($history_file)
         or return $self->log->error("load: can't ReadHistory file [$history_file]: $!");

      $self->debug && $self->log->debug("load: success");
   }
   else {
      $self->log->warning("load: cannot ReadHistory");
   }

   return 1;
}

sub write {
   my $self = shift;

   my $shell = $self->shell;
   my $history_file = $self->history_file;

   if (! defined($shell)) {
      return $self->log->error("write: you must give a shell Brick as Attribute");
   }

   if ($shell->term->can('WriteHistory')) {
      $shell->term->WriteHistory($history_file)
         or return $self->log->error("load: can't WriteHistory file [$history_file]: $!");
      $self->debug && $self->log->debug("write: success");
   }
   else {
      $self->log->warning("load: cannot WriteHistory");
   }

   return 1;
}

sub get {
   my $self = shift;

   my $shell = $self->shell;

   if (! defined($shell)) {
      return $self->log->error("get: you must give a shell Brick as Attribute");
   }

   my @history = ();
   if ($shell->term->can('GetHistory')) {
      @history = $shell->term->GetHistory;

      $self->debug && $self->log->debug("get: success");
   }
   else {
      $self->log->warning("load: cannot GetHistory");
   }

   return \@history;
}

sub get_one {
   my $self = shift;
   my ($number) = @_;

   if (! defined($number) || $number !~ /^\d+$/) {
      return $self->log->info($self->help_run('get_one'));
   }

   my $shell = $self->shell;

   if (! defined($shell)) {
      return $self->log->error("get_one: you must give a shell Brick as Attribute");
   }

   my $history = '';
   my @history = ();
   if ($shell->term->can('GetHistory')) {
      @history = $shell->term->GetHistory;
      $history = $history[$number];

      $self->debug && $self->log->debug("get_one: success");
   }
   else {
      $self->log->warning("load: cannot GetHistory");
   }

   return $history;
}

sub get_range {
   my $self = shift;
   my ($range) = @_;

   if (! defined($range) || $range !~ /^\d+\.\.\d+$/) {
      return $self->log->info($self->help_run('get_range'));
   }

   my $shell = $self->shell;

   if (! defined($shell)) {
      return $self->log->error("get_range: you must give a shell Brick as Attribute");
   }

   my @history = ();
   if ($shell->term->can('GetHistory')) {
      @history = $shell->term->GetHistory;
      @history = @history[eval($range)];

      $self->debug && $self->log->debug("get_range: success");
   }
   else {
      $self->log->warning("load: cannot GetHistory");
   }

   return \@history;
}

1;

__END__
