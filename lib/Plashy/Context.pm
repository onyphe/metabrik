#
# $Id$
#
package Plashy::Context;
use strict;
use warnings;

use base qw(Class::Gomor::Hash);

our @AS = qw(
   log
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

   my $log = $self->log;
   if (! defined($log)) {
      die("[-] FATAL: Plashy::Context::new: you have to give a `log' object\n");
   }

   my $shell = $self->shell;
   if (! defined($shell)) {
      $log->fatal("Plashy::Context::new: you have to give a `shell' object");
   }

   my $lp = Lexical::Persistence->new;
   $self->_lp($lp);

   # On first invocation, we can't use our very own call().
   eval {
      $lp->call(sub {
         my %args = @_;

         my $__lp_shell = $args{shell};

         eval("use Plashy::Brick::Global;");
         if ($@) {
            chomp($@);
            die("new: can't use Plashy::Brick::Global: $@\n");
         }

         # Only ONE special "global" variable: $global
         my $global = Plashy::Brick::Global->new(
            shell => $__lp_shell,
         );

         $global->init;

         #$global->input(\*STDIN);
         #$global->output(\*STDOUT);
      }, shell => $shell);
   };
   if ($@) {
      chomp($@);
      $log->fatal("Plashy::Context::new: can't initialize Brick global: $@");
   }

   $self->do("use strict;");
   $self->do("use warnings;");
   $self->do("use Data::Dumper;");

   return $self;
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
      $log->error("Context::do: $@");
      return;
   }

   return $res;
}

sub call {
   my $self = shift;
   my ($subref, %args) = @_;

   my $log = $self->log;
   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->call($subref, %args);
   };
   if ($@) {
      chomp($@);
      $log->error("Context::call: $@");
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

sub global_update_available_bricks {
   my $self = shift;

   my $log = $self->log;
   my $lp = $self->_lp;

   my $r = $lp->call(sub { $global->update_available_bricks; })
      or return;

   return $r;
}


1;

__END__
