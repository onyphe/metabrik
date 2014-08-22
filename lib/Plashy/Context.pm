#
# $Id$
#
package Plashy::Context;
use strict;
use warnings;

use base qw(Class::Gomor::Hash);

our @AS = qw(
   logger
   shell
   _lp
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Lexical::Persistence;

# Only used to avoid compile-time issue
my $global = {};

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $logger = $self->logger;
   if (! defined($logger)) {
      die("[-] FATAL: Plashy::Context::new: you have to give a `logger' attribute (ex: Plashy::Log::Console)\n");
   }

   my $shell = $self->shell;
   if (! defined($shell)) {
      die("[-] FATAL: Plashy::Context::new: you have to give a `shell' attribute\n");
   }

   my $lp = Lexical::Persistence->new;
   $self->_lp($lp);

   # On first invocation, we can't use our very own call().
   eval {
      $lp->call(sub {
         my %args = @_;

         my $__lp_logger = $args{logger};
         my $__lp_shell = $args{shell};

         eval("use $__lp_logger;");
         if ($@) {
            chomp($@);
            die("new: can't use [$__lp_logger]: $@\n");
         }
         eval("use Plashy::Plugin::Global;");
         if ($@) {
            chomp($@);
            die("new: can't use Plashy::Plugin::Global: $@\n");
         }

         # XXX: TODO: update of level from outside of Context
         my $log = $__lp_logger->new(
            level => 1,
         );

         # Only ONE special "global" variable: $global
         my $global = Plashy::Plugin::Global->new(
            log => $log,
            shell => $__lp_shell,
         );

         $global->init;

         #$global->input(\*STDIN);
         #$global->output(\*STDOUT);
      }, logger => $logger, shell => $shell);
   };
   if ($@) {
      chomp($@);
      die("[-] FATAL: Plashy::Context::new: can't initialize global plugin: $@\n");
   }

   $self->do("use strict;");
   $self->do("use warnings;");
   $self->do("use Data::Dumper;");

   return $self;
}

sub log {
   my $self = shift;

   my $log = $self->call(sub { return $global->log; });
   if (! defined($log)) {
      die("[-] FATAL: Plashy::Context::log: can't get access to log object\n");
   }

   return $log;
}

sub do {
   my $self = shift;
   my ($code) = @_;

   my $log = $self->log;
   my $lp = $self->_lp;

   my $echo = $self->global_get('echo');

   my $res;
   eval {
      if ($echo) {
         $res = Data::Dump::dump($lp->do($code));
         print "$res\n";
      }
      else {
         $res = $lp->do($code);
      }
   };
   if ($@) {
      chomp($@);
      $log->error("do: $@");
      return;
   }

   return $res;
}

sub call {
   my $self = shift;
   my ($subref, %args) = @_;

   my $lp = $self->_lp;

   # We can't use sub log() here, otherwise we have a recursive loop
   my $log;
   eval {
      $log = $lp->call(sub { return $global->log });
   };
   if ($@) {
      chomp($@);
      die("[-] FATAL: Plashy::Context::call: can't get access to log object: $@\n");
   }

   my $res;
   eval {
      $res = $lp->call($subref, %args);
   };
   if ($@) {
      chomp($@);
      $log->error("call: $@");
      return;
   }

   return $res;
}

sub global_get {
   my $self = shift;
   my ($var) = @_;

   my $log = $self->log;

   my $value = $self->call(sub {
      my %args = @_;

      my $__lp_var = $args{var};
      my $__lp_value = $global->$__lp_var;

      return $__lp_value;
   }, var => $var);

   return $value;
}

sub global_update_available_plugins {
   my $self = shift;

   my $log = $self->log;
   my $lp = $self->_lp;

   my $r = $lp->call(sub { $global->update_available_plugins; })
      or $log->error("global_update_available_plugins");

   return $r;
}


1;

__END__
