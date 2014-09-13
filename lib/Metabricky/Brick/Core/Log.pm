#
# $Id$
#
package Metabricky::Brick::Core::Log;
use strict;
use warnings;

use base qw(Metabricky::Ext::Log Metabricky::Brick);
__PACKAGE__->cgBuildIndices;

use Term::ANSIColor qw(:constants);

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
   return;
}

sub fatal {
   my $self = shift;
   my ($msg) = @_;
   print RED, "[FATAL] ", RESET;
   die("$msg\n");
}

sub info {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 0;
   print GREEN, "[*] ", RESET;
   print("$msg\n");
   return 1;
}

sub verbose {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 1;
   print YELLOW, "[+] ", RESET;
   print("$msg\n");
   return 1;
}

sub debug {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 2;
   my ($package) = caller();
   print BLUE, "[DEBUG] ", RESET;
   print("$package: $msg\n");
   return 1;
}

1;

__END__

=head1 NAME

Metabricky::Brick::Core::Log - logging directly on the console

=head1 SYNOPSIS

   use Metabricky::Brick::Core::Log;

   my $log = Metabricky::Brick::Core::Log->new(
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
