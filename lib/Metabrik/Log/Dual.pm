#
# $Id$
#
# log::dual Brik
#
package Metabrik::Log::Dual;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(log) ],
      attributes => {
         level => [ qw(0|1|2|3) ],
         output_file => [ qw(file) ],
         _fd => [ qw(file_descriptor) ],
      },
      commands => {
         info => [ qw(string) ],
         verbose => [ qw(string) ],
         warning => [ qw(string) ],
         error => [ qw(string) ],
         fatal => [ qw(string) ],
         debug => [ qw(string) ],
      },
      require_modules => {
         'Term::ANSIColor' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         debug => $self->log->debug,
         level => $self->log->level,
         output_file => $self->global->output,
      },
   };
}

sub brik_preinit {
   my $self = shift;

   my $context = $self->context;

   # We replace the current logging Brik by this one.
   $context->{log} = $self;
   for my $this (keys %{$context->used}) {
      $context->{used}->{$this}->{log} = $self;
   }

   # We have to init this new log Brik, because previous one
   # was already inited at this stage. We have to keep the same init context.
   $self->brik_init or return $self->log->error("brik_preinit: init error");

   return $self;
}

sub brik_init {
   my $self = shift->SUPER::brik_init(
      @_,
   ) or return 1; # Init already done

   print "DEBUG log::dual brik_init\n";

   my $output_file = $self->output_file;
   open(my $fd, '>', $output_file)
      or return $self->log->error("brik_init: can't open output file [$output_file]: $!");

   # Makes the file handle unbuffered
   my $current = select;
   select($fd);
   $|++;
   select($current);

   $self->_fd($fd);

   return $self;
}

sub _msg {
   my $self = shift;
   my ($brik, $msg) = @_;

   $msg ||= 'undef';

   $brik =~ s/^metabrik::brik:://i;

   return lc($brik).": $msg\n";
}

sub warning {
   my $self = shift;
   my ($msg) = @_;

   my $buffer = "[!] ".$self->_msg(my ($caller) = caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   return 1;
}

sub error {
   my $self = shift;
   my ($msg) = @_;

   my $buffer = "[-] ".$self->_msg(my ($caller) = caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   return 0;
}

sub fatal {
   my $self = shift;
   my ($msg) = @_;

   my $buffer = "[F] ".$self->_msg(my ($caller) = caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   die($buffer);
}

sub info {
   my $self = shift;
   my ($msg) = @_;

   return 0 unless $self->level > 0;

   $msg ||= 'undef';

   my $buffer = "[+] $msg\n";

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   return 1;
}

sub verbose {
   my $self = shift;
   my ($msg) = @_;

   return 1 unless $self->level > 1;

   my $buffer = "[*] ".$self->_msg(my ($caller) = caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   return 1;
}

sub debug {
   my $self = shift;
   my ($msg) = @_;

   # We have a conflict between the method and the accessor,
   # we have to identify which one is accessed.

   # If no message defined, we want to access the Attribute
   if (! defined($msg)) {
      return $self->{debug};
   }
   else {
      # If $msg is either 1 or 0, we want to set the Attribute
      if ($msg =~ /^(?:1|0)$/) {
         return $self->{debug} = $msg;
      }
      else {
         return 1 unless $self->level > 2;

         my $buffer = "[D] ".$self->_msg(my ($caller) = caller(), $msg);

         my $fd = $self->_fd;

         print $fd $buffer;
         print $buffer;
      }
   }

   return 1;
}

sub brik_fini {
   my $self = shift;

   my $fd = $self->_fd;
   if (defined($fd)) {
      close($fd);
      $self->_fd(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Log::Dual - log::dual Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
