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
         time_prefix => [ qw(0|1) ],
         text_prefix => [ qw(0|1) ],
         _fd => [ qw(file_descriptor) ],
      },
      attributes_default => {
         time_prefix => 0,
         text_prefix => 0,
      },
      commands => {
         info => [ qw(string caller|OPTIONAL) ],
         verbose => [ qw(string caller|OPTIONAL) ],
         warning => [ qw(string caller|OPTIONAL) ],
         error => [ qw(string caller|OPTIONAL) ],
         fatal => [ qw(string caller|OPTIONAL) ],
         debug => [ qw(string caller|OPTIONAL) ],
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
   my $self = shift;

   my $output_file = $self->output_file;
   open(my $fd, '>', $output_file)
      or return $self->log->error("brik_init: can't open output file [$output_file]: $!");

   # Makes the file handle unbuffered
   my $current = select;
   select($fd);
   $|++;
   select($current);

   $self->_fd($fd);

   return $self->SUPER::brik_init;
}

sub _msg {
   my $self = shift;
   my ($brik, $msg) = @_;

   $msg ||= 'undef';

   $brik =~ s/^metabrik:://i;

   return lc($brik).": $msg\n";
}

sub warning {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $prefix = $self->text_prefix ? "WARN " : "[!]";
   my $time = $self->time_prefix ? localtime()." " : " ";
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   return 1;
}

sub error {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $prefix = $self->text_prefix ? "ERROR" : "[-]";
   my $time = $self->time_prefix ? localtime()." " : " ";
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   # Returning undef is my official way of stating an error occured:
   # Number 0 is for stating a false condition occured, not not error.
   return;
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $prefix = $self->text_prefix ? "FATAL" : "[F]";
   my $time = $self->time_prefix ? localtime()." " : " ";
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   die($buffer);
}

sub info {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 0;

   $msg ||= 'undef';

   my $prefix = $self->text_prefix ? "INFO " : "[+]";
   my $time = $self->time_prefix ? localtime()." " : " ";
   my $buffer = $time."$prefix $msg\n";

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   return 1;
}

sub verbose {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 1;

   my $prefix = $self->text_prefix ? "VERB " : "[*]";
   my $time = $self->time_prefix ? localtime()." " : " ";
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   my $fd = $self->_fd;

   print $fd $buffer;
   print $buffer;

   return 1;
}

sub debug {
   my $self = shift;
   my ($msg, $caller) = @_;

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

         my $prefix = $self->text_prefix ? "DEBUG" : "[D]";
         my $time = $self->time_prefix ? localtime()." " : " ";
         my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

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

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
