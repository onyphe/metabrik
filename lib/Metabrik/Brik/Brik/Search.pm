#
# $Id$
#
# brik::search Brik
#
package Metabrik::Brik::Brik::Search;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_tags {
   return [ qw(unstable) ];
}

sub help {
   return {
      'run:all' => '',
      'run:string' => '<string>',
   };
}

sub all {
   my $self = shift;

   my $status = $self->context->status;

   $self->log->info("Available briks:");

   my $total = 0;
   my $count = 0;
   $self->log->info("   Used:");
   for my $used (@{$status->{used}}) {
      $self->log->info("      $used");
      $count++;
      $total++;
   }
   $self->log->info("   Count: $count");

   $count = 0;
   $self->log->info("   Not used:");
   for my $not_used (@{$status->{not_used}}) {
      $self->log->info("      $not_used");
      $count++;
      $total++;
   }
   $self->log->info("   Count: $count");

   $self->log->info("Total: $total");

   return $total;
}

sub string {
   my $self = shift;
   my ($string) = @_;

   if (! defined($string)) {
      return $self->log->info($self->help_run('string'));
   }

   my $status = $self->context->status;

   $self->log->info("Available briks:");

   my $total = 0;
   $self->log->info("   Used:");
   for my $used (@{$status->{used}}) {
      next unless $used =~ /$string/;
      $self->log->info("      $used");
      $total++;
   }

   $self->log->info("   Not used:");
   for my $not_used (@{$status->{not_used}}) {
      next unless $not_used =~ /$string/;
      $self->log->info("      $not_used");
      $total++;
   }

   return 1;
}

1;

__END__
