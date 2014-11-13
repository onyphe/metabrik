#
# $Id$
#
# audit::https Brik
#
package Metabrik::Audit::Https;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(https audit ssl openssl) ],
      attributes => {
         uri => [ qw(uri) ],
      },
      commands => {
         check_ssl3_support => [ ],
      },
      require_used => {
         'string::uri' => [ ],
         'shell::command' => [ ],
      },
      require_binaries => {
         'printf' => [ ],
         'openssl' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         uri => $self->global->uri,
      },
   };
}

# Poodle: http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-3566
#
sub check_ssl3_support {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;

   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('check_ssl3_support'));
   }

   if ($uri !~ /^https:\/\//) {
      return $self->log->error("check_ssl3_support: uri [$uri] invalid format");
   }

   my $context = $self->context;

   $context->run('string::uri', 'parse', $uri) or return;
   my $host = $context->run('string::uri', 'host') or return;
   my $port = $context->run('string::uri', 'port') or return;

   my $cmd = "printf \"GET / HTTP/1.0\r\n\r\n\" | openssl s_client -host $host -port $port -ssl3";

   $context->set('shell::command', 'capture_stderr', 1);
   my $buf = $context->run('shell::command', 'capture', $cmd)
      or return $self->log->error("check_ssl3_support: shell::command error");

   my $check = {
      ssl_version3_support => 1,
      cmd => $cmd,
      raw => $buf,
   };
   for (@$buf) {
      if (/sslv3 alert handshake failure/s) {
         $check->{ssl_version3_support} = 0;
         last;
      }
   }

   return $check;
}

1;

__END__
