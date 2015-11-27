#
# $Id$
#
# client::twitter Brik
#
package Metabrik::Client::Twitter;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable client twitter) ],
      commands => {
         connect => [ qw(consumer_key|OPTIONAL consumer_secret|OPTIONAL access_token|OPTIONAL access_token_secret|OPTIONAL) ],
         tweet => [ qw(message) ],
      },
      attributes => {
         consumer_key => [ qw(string) ],
         consumer_secret => [ qw(string) ],
         access_token => [ qw(string) ],
         access_token_secret => [ qw(string) ],
         net_twitter => [ qw(object|INTERNAL) ],
      },
      require_modules => {
         'Net::Twitter' => [ ],
      },
   };
}

sub connect {
   my $self = shift;
   my ($consumer_key, $consumer_secret, $access_token, $access_token_secret) = @_;

   if (defined($self->net_twitter)) {
      return $self->log->info("connect: already connected");
   }

   # Get API keys: authenticate and go to https://apps.twitter.com/app/new

   $consumer_key ||= $self->consumer_key;
   $consumer_secret ||= $self->consumer_secret;
   $access_token ||= $self->access_token;
   $access_token_secret ||= $self->access_token_secret;

   if (! defined($consumer_key)) {
      return $self->log->error($self->brik_help_run('tweet'));
   }
   if (! defined($consumer_secret)) {
      return $self->log->error($self->brik_help_run('tweet'));
   }
   if (! defined($access_token)) {
      return $self->log->error($self->brik_help_run('tweet'));
   }
   if (! defined($access_token_secret)) {
      return $self->log->error($self->brik_help_run('tweet'));
   }

   # Without that, we got:
   # "500 Can't connect to api.twitter.com:443 (Crypt-SSLeay can't verify hostnames)"
   $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

   my $nt;
   eval {
      $nt = Net::Twitter->new(
         traits => [qw/API::RESTv1_1/],
         consumer_key => $consumer_key,
         consumer_secret => $consumer_secret,
         access_token => $access_token,
         access_token_secret => $access_token_secret,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("connect: unable to connect [$@]");
   }
   elsif (! defined($nt)) {
      return $self->log->error("connect: unable to connect [unknown error]");
   }

   return $self->net_twitter($nt);
}

sub tweet {
   my $self = shift;
   my ($message) = @_;

   if (! defined($message)) {
      return $self->log->error($self->brik_help_run('tweet'));
   }

   my $nt = $self->net_twitter;
   if (! defined($nt)) {
      $nt = $self->connect or return;
   }

   my $r;
   eval {
      $r = $nt->update($message);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("tweet: unable to tweet [$@]");
   }
   elsif (! defined($r)) {
      return $self->log->error("connect: unable to tweet [unknown error]");
   }

   return $message;
}

1;

__END__

=head1 NAME

Metabrik::Client::Twitter - client::twitter Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
