#
# $Id$
#
# www::splunk Brik
#
package Metabrik::Www::Splunk;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(splunk_uri) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         ssl_verify => [ qw(0|1) ],
         _splunk => [ qw(object|INTERNAL) ],
      },
      attributes_default => {
         uri => 'https://localhost:8089',
         username => 'admin',
         password => 'changeme',
         ssl_verify => 0,
      },
      commands => {
         install => [ ], # Inherited
         connect => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         search => [ qw(search_string) ],
      },
      require_modules => {
         'Net::SSL' => [ ],
         'WWW::Splunk' => [ ],
         'Metabrik::String::Uri' => [ ],
      },
      need_packages => {
         'ubuntu' => [ qw(libssl-dev) ],
      },
   };
}

sub connect {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $uri ||= $self->uri;
   $username ||= $self->username;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('connect', $uri) or return;
   $self->brik_help_run_undef_arg('connect', $username) or return;
   $self->brik_help_run_undef_arg('connect', $password) or return;

   my $su = Metabrik::String::Uri->new_from_brik_init($self) or return;
   my $parsed = $su->parse($uri) or return;

   my $splunk;
   eval {
      $splunk = WWW::Splunk->new({
         host => $parsed->{host},
         port => $parsed->{port},
         login => $username,
         password => $password,
         unsafe_ssl => 1, #! $self->ssl_verify,
      });
   };
   if ($@) {
      chomp($@);
      return $self->log->error("connect: unable to conncet to [$uri]: $@");
   }

   $self->_splunk($splunk);

   $self->log->verbose("connect: success");

   return 1;
}

sub search {
   my $self = shift;
   my ($search_string) = @_;

   my $splunk = $self->_splunk;
   $self->brik_help_run_undef_arg('connect', $splunk) or return;
   $self->brik_help_run_undef_arg('search', $search_string) or return;

   $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'Net::SSL';

   my $sid;
   eval {
      $sid = $splunk->start_search($search_string);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("search: starting search failed: [$@]");
   }

   eval {
      $splunk->poll_search($sid);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("search: polling search failed: [$@]");
   }

   until ($splunk->results_read($sid)) {
      print scalar $splunk->search_results($sid);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Www::Splunk - www::splunk Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
