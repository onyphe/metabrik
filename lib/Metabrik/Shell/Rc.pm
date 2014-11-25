#
# $Id$
#
# shell::rc Brik
#
package Metabrik::Shell::Rc;
use strict;
use warnings;

our $VERSION = '1.02';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main shell rc) ],
      attributes => {
         rc_file => [ qw(file) ],
         create_default => [ qw(0|1) ],
      },
      commands => {
         load => [ ],
         write_default => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         rc_file => $self->global->homedir.'/.metabrik_rc',
         create_default => 1,
      },
   };
}

sub load {
   my $self = shift;

   my $rc_file = $self->rc_file;

   if (! -f $rc_file && $self->create_default) {
      $self->write_default;
   }

   if (! -f $rc_file && ! $self->create_default) {
      return $self->log->error("load: can't find rc file [$rc_file]");
   }

   my @lines = ();
   my @multilines = ();
   open(my $in, '<', $rc_file)
         or return $self->log->error("local: can't open rc file [$rc_file]: $!");
   while (defined(my $this = <$in>)) {
      chomp($this);
      next if ($this =~ /^\s*#/);  # Skip comments
      next if ($this =~ /^\s*$/);  # Skip blank lines

      push @multilines, $this;

      # First line of a multiline
      if ($this =~ /\\\s*$/) {
         next;
      }

      # Multiline edition finished, we can remove the `\' char before joining
      for (@multilines) {
         s/\\\s*$//;
      }

      $self->debug && $self->log->debug("load: multilines[@multilines]");

      my $line = join('', @multilines);
      @multilines = ();

      push @lines, $line;
   }
   close($in);

   $self->debug && $self->log->debug("load: success");

   return \@lines;
}

sub write_default {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->rc_file;

   if (-f $file) {
      return $self->log->error("create: file [$file] already exists");
   }

   open(my $out, '>', $file)
      or return $self->log->error("create: open: file [$file]: $!");

   my $content = <<EOF;
set core::shell echo 0

my \$home = \$ENV{HOME}
my \$user = \$ENV{USER}

my \$datadir = "\$home/metabrik"
my \$repository = "\$datadir/repository/lib"

push \@INC, \$repository
run core::context update_available

set core::global datadir \$datadir
set core::global ctimeout 20
set core::global rtimeout 20

use shell::command

alias update_available "run core::context update_available"
alias reuse "run core::context reuse"
alias system "run shell::command system"
alias capture "run shell::command capture"
alias install "run perl::module install"
alias search "run brik::search"
alias show "run brik::search all"
alias ls "capture ls -F"
alias l "ls -l"
alias w "capture w"
alias perldoc "system perldoc"
alias top "system top"
alias history "run shell::history show"
alias ! "run shell::history exec"
alias cat "run shell::command capture cat"
alias pwd "run core::shell pwd"

use shell::history
run shell::history load

set core::shell echo 1
EOF

   print $out $content;

   close($out);

   $self->log->verbose("create: default rc file [$file] created");

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Shell::Rc - shell::rc Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
