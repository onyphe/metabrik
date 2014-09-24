#
# $Id: Log.pm 89 2014-09-17 20:29:29Z gomor $
#
package Metabricky::Brick::Core::Log;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   level
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub require_modules {
   return [
      'Term::ANSIColor',
   ];
}

sub revision {
   return '$Revision$';
}

sub help {
   return {
      'set:level' => '<0|1|2|3>',
      'run:info' => '<message>',
      'run:verbose' => '<message>',
      'run:warning' => '<message>',
      'run:error' => '<message>',
      'run:fatal' => '<message>',
      'run:debug' => '<message>',
   };
}

sub default_values {
   return {
      level => 1,
   };
}

sub warning {
   my $self = shift;
   my ($msg) = @_;
   $msg ||= 'undef';
   my ($package) = lc(caller());
   $package =~ s/^metabricky::brick:://;
   print("[!] $package: $msg\n");
}

sub error {
   my $self = shift;
   my ($msg) = @_;
   $msg ||= 'undef';
   my ($package) = lc(caller());
   $package =~ s/^metabricky::brick:://;
   print Term::ANSIColor::RED(), "[-] ", Term::ANSIColor::RESET();
   print("$package: $msg\n");
   return;
}

sub fatal {
   my $self = shift;
   my ($msg) = @_;
   $msg ||= 'undef';
   my ($package) = lc(caller());
   $package =~ s/^metabricky::brick:://;
   print Term::ANSIColor::RED(), "[FATAL] ", Term::ANSIColor::RESET();
   die("$package: $msg\n");
}

sub info {
   my $self = shift;
   my ($msg) = @_;
   $msg ||= 'undef';
   return unless $self->level > 0;
   print Term::ANSIColor::GREEN(), "[*] ", Term::ANSIColor::RESET();
   print("$msg\n");
   return 1;
}

sub verbose {
   my $self = shift;
   my ($msg) = @_;
   $msg ||= 'undef';
   return unless $self->level > 1;
   my ($package) = lc(caller());
   $package =~ s/^metabricky::brick:://;
   print Term::ANSIColor::YELLOW(), "[+] ", Term::ANSIColor::RESET();
   print("$package: $msg\n");
   return 1;
}

sub debug {
   my $self = shift;
   my ($msg) = @_;
   $msg ||= 'undef';
   return unless $self->level > 2;
   my ($package) = lc(caller());
   $package =~ s/^metabricky::brick:://;
   print Term::ANSIColor::BLUE(), "[D] ", Term::ANSIColor::RESET();
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
