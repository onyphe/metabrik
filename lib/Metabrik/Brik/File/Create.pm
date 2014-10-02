#
# $Id$
#
# file::create Brik
#
package Metabrik::Brik::File::Create;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      max_size => [],
   };
}

sub help {
   return {
      'set:max_size' => '<value>',
      'run:fixed_size' => '<filename>',
   };
}

sub default_values {
   return {
      max_size => 10_000_000, # 10MB
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   # Do your init here

   return $self;
}

sub fixed_size {
   my $self = shift;
   my ($filename) = @_;

   if (! defined($filename)) {
      return $self->log->info($self->help_run('fixed_size'));
   }

   system("dd if=/dev/zero of=$filename bs=1 count=".$self->max_size);

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Brik::File::Create - Brik to create files in different manners

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
