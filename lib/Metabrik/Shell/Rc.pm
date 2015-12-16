#
# $Id$
#
# shell::rc Brik
#
package Metabrik::Shell::Rc;
use strict;
use warnings;

our $VERSION = '1.20';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main core) ],
      attributes => {
         file => [ qw(file) ],
         create_default => [ qw(0|1) ],
      },
      attributes_default => {
         create_default => 1,
      },
      commands => {
         load => [ qw(input_file|OPTIONAL) ],
         exec => [ qw($line_list) ],
         write_default => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         file => $self->global->homedir.'/.metabrik_rc',
      },
   };
}

sub load {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->file;

   if (! -f $file && $self->create_default) {
      $self->write_default;
   }

   if (! -f $file && ! $self->create_default) {
      return $self->log->error("load: can't find rc file [$file]");
   }

   my @lines = ();
   open(my $in, '<', $file)
         or return $self->log->error("local: can't open rc file [$file]: $!");
   while (defined(my $line = <$in>)) {
      chomp($line);
      next if $line =~ /^\s*$/;   # Skip blank lines
      next if $line =~ /^\s*#/;   # Skip comments
      $line =~ s/^(.*)#.*$/$1/;   # Strip comments at end of line
      push @lines, "$line ";      # Add a trailing slash in case of a multiline
                                  # So when joining them, there is no unwanted concatenation
   }
   close($in);

   $self->debug && $self->log->debug("load: success");

   return \@lines;
}

sub exec {
   my $self = shift;
   my ($lines) = @_;

   if (! defined($lines)) {
      return $self->log->error($self->brik_help_run('exec'));
   }

   if (ref($lines) ne 'ARRAY') {
      return $self->log->error("exec: must give an ARRAYREF as argument");
   }

   my $shell = $self->shell;

   $shell->cmdloop($lines);

   return 1;
}

sub write_default {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->file;

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
my \$sudo = "sudo -E \$0 --no-splash"

push \@INC, \$repository
run core::context update_available

set core::global datadir \$datadir
set core::global repository \$repository
set core::global ctimeout 20
set core::global rtimeout 20

alias update_available "run core::context update_available"
alias reuse "run core::context reuse"
alias pwd "run core::shell pwd"

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

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
