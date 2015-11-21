#
# $Id$
#
# brik::search Brik
#
package Metabrik::Brik::Search;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable main brik search) ],
      commands => {
         all => [ ],
         string => [ qw(string) ],
         tag => [ qw(Tag) ],
         not_tag => [ qw(Tag) ],
         used => [ ],
         not_used => [ ],
         show_require_modules => [ ],
         command => [ qw(Command) ],
      },
   };
}

sub all {
   my $self = shift;

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   my $count = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      my $tags = $context->used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $count++;
      $total++;
   }
   $self->log->info("Count: $count");

   $count = 0;
   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      my $tags = $context->not_used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $count++;
      $total++;
   }
   $self->log->info("Count: $count");

   return $total;
}

sub string {
   my $self = shift;
   my ($string) = @_;

   if (! defined($string)) {
      return $self->log->error($self->brik_help_run('string'));
   }

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      next unless $brik =~ /$string/;
      my $tags = $context->used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $total++;
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      next unless $brik =~ /$string/;
      my $tags = $context->not_used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $total++;
   }

   return $total;
}

sub tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($tag)) {
      return $self->log->error($self->brik_help_run('tag'));
   }

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      my $tags = $context->used->{$brik}->brik_tags;
      push @$tags, 'used';
      for my $this (@$tags) {
         next unless $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      my $tags = $context->not_used->{$brik}->brik_tags;
      push @$tags, 'not_used';
      for my $this (@$tags) {
         next unless $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }


   return $total;
}

sub not_tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($tag)) {
      return $self->log->error($self->brik_help_run('not_tag'));
   }

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      my $tags = $context->used->{$brik}->brik_tags;
      push @$tags, 'used';
      for my $this (@$tags) {
         next if $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      my $tags = $context->not_used->{$brik}->brik_tags;
      push @$tags, 'not_used';
      for my $this (@$tags) {
         next if $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }

   return $total;
}

sub used {
   my $self = shift;

   return $self->tag('used');
}

sub not_used {
   my $self = shift;

   return $self->not_tag('used');
}

sub show_require_modules {
   my $self = shift;

   my $context = $self->context;
   my $available = $context->available;

   # Don't show require for Metabrik::Core
   my $core = {
      'shell::script',
      'shell::rc',
      'shell::history',
      'shell::command',
      'brik::search',
      'perl::module',
      'core::context',
      'core::log',
      'core::shell',
      'core::global',
   };

   my %require_modules = ();
   for my $brik (keys %$available) {
      next if (exists($core->{$brik}));
      if ($available->{$brik}->can('brik_properties')) {
         my $modules = $available->{$brik}->brik_properties->{require_modules};
         for my $module (keys %$modules) {
            next if $module =~ /^Metabrik/;
            $require_modules{$module} = $brik;
         }
      }
   }

   return [ sort { $a cmp $b } keys %require_modules ];
}

sub command {
   my $self = shift;
   my ($command) = @_;

   if (! defined($command)) {
      return $self->log->error($self->brik_help_run('command'));
   }

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      if (exists($context->used->{$brik}->brik_properties->{commands})) {
         my $tags = $context->used->{$brik}->brik_tags;
         push @$tags, 'used';
         for my $key (keys %{$context->used->{$brik}->brik_properties->{commands}}) {
            if ($key =~ /$command/i) {
               $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
               $total++;
            }
         }
      }
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      if (exists($context->not_used->{$brik}->brik_properties->{commands})) {
         my $tags = $context->not_used->{$brik}->brik_tags;
         push @$tags, 'not_used';
         for my $key (keys %{$context->not_used->{$brik}->brik_properties->{commands}}) {
            if ($key =~ /$command/i) {
               $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
               $total++;
            }
         }
      }
   }

   return $total;
}

1;

__END__

=head1 NAME

Metabrik::Brik::Search - brik::search Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
