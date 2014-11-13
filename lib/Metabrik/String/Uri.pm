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
         uri => [ qw(URI) ],
      },
      commands => {
         parse => [ qw(uri) ],
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
      },
      require_modules => {
         URI => [ ],
      },
   };
}

sub parse {
   my $self = shift;
   my ($uri) = @_;

   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('parse'));
   }

   my $parse = URI->new($uri);
   $self->uri($parse);

   return $parse;
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

sub tld {
   my $self = shift;

   my $uri = $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('parse'));
   }

   my $host = $uri->host;

   my ($tld) = $host =~ /^.*\.(\S+)$/;

   return $tld;
}

sub hostname {
   my $self = shift;

   my $uri = $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('parse'));
   }

   my $host = $uri->host;

   # Only 1 dot, we don't have hostname
   my @count = ($host =~ /\./g);
   if (@count == 1) {
      return '';
   }

   my ($hostname) = $host =~ /^(.*?)\..*$/;

   return $hostname;
}

sub domain {
   my $self = shift;

   my $uri = $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('parse'));
   }

   my $host = $uri->host;

   my ($domain) = $host =~ /^.*?\.(.+)$/;

   # We only have domain.tld, we return it
   if ($domain !~ /\./) {
      return $host;
   }

   return $domain;
}

1;

__END__
