#
# $Id$
#
package Plashy::Log;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   level
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Term::ANSIColor qw(:constants);

sub new {
   my $self = shift->SUPER::new(
      level => 0,
      @_,
   );

   return $self;
}

sub warning {
   my $self = shift;
   my ($msg) = @_;
   print("[!] $msg\n");
}

sub error {
   my $self = shift;
   my ($msg) = @_;
   print RED, "[-] ", RESET;
   print("$msg\n");
}

sub fatal {
   my $self = shift;
   my ($msg) = @_;
   my ($package) = caller();
   print RED, "[-] FATAL: ", RESET;
   die("$package: $msg\n");
}

sub info {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 0;
   print GREEN, "[*] ", RESET;
   print("$msg\n");
}

sub verbose {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 1;
   print YELLOW, "[+] ", RESET;
   print("$msg\n");
}

sub debug {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 2;
   my ($package) = caller();
   print BLUE, "[DEBUG] ", RESET;
   print("$package: $msg\n");
}

1;

__END__

=head1 NAME

Plashy::Log - logging base-class

=head1 SYNOPSIS

   use Plashy::Log;

   my $log = Plashy::Log->new(
      level => 1,
   );

=head1 DESCRIPTION

=head1 COMMANDS

=over 4

=item B<new>

=item B<info>

=item B<warning>

=item B<error>

=item B<fatal>

=item B<verbose>

=item B<debug>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
