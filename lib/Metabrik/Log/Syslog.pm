#
# $Id$
#
# log::syslog Brik
#
package Metabrik::Log::Syslog;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         level => [ qw(0|1|2|3) ],
         host => [ qw(syslog_host) ],
         port => [ qw(syslog_port) ],
         time_prefix => [ qw(0|1) ],
         text_prefix => [ qw(0|1) ],
         facility => [ qw(kernel|user|mail|system|security|internal|printer|news|uucp|clock|security2|FTP|NTP|audit|alert|clock2|local0|local1|local2|local3|local4|local5|local6|local7) ],
         name => [ qw(program) ],
         _fd => [ qw(INTERNAL) ],
      },
      attributes_default => {
         level => 2,
         time_prefix => 0,
         text_prefix => 1,
         host => '127.0.0.1',
         port => 514,
         facility => 'local5',
         name => 'metabrik',
      },
      commands => {
         send => [ qw(message priority) ],
         info => [ qw(string caller|OPTIONAL) ],
         verbose => [ qw(string caller|OPTIONAL) ],
         warning => [ qw(string caller|OPTIONAL) ],
         error => [ qw(string caller|OPTIONAL) ],
         fatal => [ qw(string caller|OPTIONAL) ],
         debug => [ qw(string caller|OPTIONAL) ],
      },
      require_modules => {
         'Net::Syslog' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         debug => $self->log->debug,
         level => $self->log->level,
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

   my $fd = Net::Syslog->new;
   if (! defined($fd)) {
      return $self->log->error("brik_init: failed to initialize Net::Syslog");
   }

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

sub send {
   my $self = shift;
   my ($msg, $priority) = @_;

   $self->brik_help_run_undef_arg('send', $msg) or return;
   $self->brik_help_run_undef_arg('send', $priority) or return;

   my $fd = $self->_fd; # Must have been inited or Brik has already failed
   my $host = $self->host;
   my $port = $self->port;
   my $name = $self->name;
   my $facility = $self->facility;

   # Priorities can be:
   # emergency, alert, critical, error, warning, notice, informational, debug

   my $r = $fd->send(
      $msg,
      Name => $name,
      Facility => $facility,
      Priority => $priority,
      SyslogHost => $host,
      SyslogPort => $port,
   );
   if (! defined($r)) {
      return $self->log->error("send: unable to send message to [$host]:$port");
   }

   return 1;
}

sub warning {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $prefix = $self->text_prefix ? 'WARN ' : '[!]';
   my $time = $self->time_prefix ? localtime().' ' : '';
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   return $self->send($buffer, 'warning');
}

sub error {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $prefix = $self->text_prefix ? 'ERROR' : '[-]';
   my $time = $self->time_prefix ? localtime().' ' : '';
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   return $self->send($buffer, 'error');
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $prefix = $self->text_prefix ? 'FATAL' : '[F]';
   my $time = $self->time_prefix ? localtime().' ' : '';
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   $self->send($buffer, 'critical');

   die($buffer);
}

sub info {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 0;

   $msg ||= 'undef';

   my $prefix = $self->text_prefix ? 'INFO ' : '[+]';
   my $time = $self->time_prefix ? localtime().' ' : '';
   my $buffer = $time."$prefix $msg\n";

   return $self->send($buffer, 'informational');
}

sub verbose {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 1;

   my $prefix = $self->text_prefix ? 'VERB ' : '[*]';
   my $time = $self->time_prefix ? localtime().' ' : '';
   my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

   return $self->send($buffer, 'notice');
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

         my $prefix = $self->text_prefix ? 'DEBUG' : '[D]';
         my $time = $self->time_prefix ? localtime().' ' : '';
         my $buffer = $time."$prefix ".$self->_msg(($caller) ||= caller(), $msg);

         $self->send($buffer, 'debug') or return;
      }
   }

   return 1;
}

sub brik_fini {
   my $self = shift;

   $self->_fd(undef);

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Log::Syslog - log::syslog Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
