#
# $Id$
#
# string::uri Brik
#
package Metabrik::String::Uri;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable uri string) ],
      attributes => {
         uri => [ qw(uri) ],
      },
      commands => {
         parse => [ qw(uri|OPTIONAL) ],
         scheme => [ ],
         host => [ ],
         port => [ ],
         tld => [ ],
         domain => [ ],
         hostname => [ ],
         path => [ ],
         opaque => [ ],
         fragment => [ ],
         query => [ ],
         path_query => [ ],
         authority => [ ],
         query_form => [ ],
         userinfo => [ ],
         is_https_scheme => [ ],
      },
      require_modules => {
         'URI' => [ ],
      },
   };
}

sub parse {
   my $self = shift;
   my ($string) = @_;

   $string ||= $self->uri;
   if (! defined($string)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   my $uri = URI->new($string);

   # Probably not a valid uri
   if (! $uri->can('host')) {
      return $self->log->error("parse: invalid URI [$string]");
   }

   return {
      scheme => $uri->scheme || '',
      host => $uri->host || '',
      port => $uri->port || 80,
      path => $uri->path || '/',
      opaque => $uri->opaque || '',
      fragment => $uri->fragment || '',
      query => $uri->query || '',
      path_query => $uri->path_query || '',
      query_form => $uri->query_form || '',
      userinfo => $uri->userinfo || '',
      authority => $uri->authority || '',
   };
}

sub is_https_scheme {
   my $self = shift;
   my ($parsed) = @_;

   if (! defined($parsed)) {
      return $self->log->error($self->brik_help_run('is_https_scheme'));
   }

   if (exists($parsed->{scheme}) && $parsed->{scheme} eq 'https') {
      return 1;
   }

   return 0;
}

sub _this {
   my $self = shift;
   my ($this) = @_;

   my $uri = $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('parse'));
   }

   return $uri->$this;
}

sub scheme { return shift->_this('scheme'); }
sub host { return shift->_this('host'); }
sub port { return shift->_this('port'); }
sub path { return shift->_this('path'); }
sub opaque { return shift->_this('opaque'); }
sub fragment { return shift->_this('fragment'); }
sub query { return shift->_this('query'); }
sub path_query { return shift->_this('path_query'); }
sub authority { return shift->_this('authority'); }
sub query_form { return shift->_this('query_form'); }
sub userinfo { return shift->_this('userinfo'); }

1;

__END__

=head1 NAME

Metabrik::String::Uri - string::uri Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
