#
# $Id: Html.pm 178 2014-10-02 18:03:00Z gomor $
#
# encoding::html Brik
#
package Metabrik::Encoding::Html;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable encode decode html escape) ],
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'URI::Escape' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('encode'));
   }

   my $encoded = URI::Escape::uri_escape($data);

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('decode'));
   }

   my $decoded = URI::Escape::uri_unescape($data);

   return $decoded;
}

1;

__END__
