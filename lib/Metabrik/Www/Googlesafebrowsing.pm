#
# $Id: Googlesafebrowsing.pm 179 2014-10-02 18:04:01Z gomor $
#
# www::googlesafebrowsing Brik
#
package Metabrik::Www::Googlesafebrowsing;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(experimental google www) ],
      attributes => {
         key => [ qw(api_key) ],
         storage => [ qw(file) ],
      },
      commands => {
         update => [ ],
      },
      require_modules => {
         'Net::Google::SafeBrowsing2' => [ ], 
         'Net::Google::SafeBrowsing2::Sqlite' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         storage => $self->global->datadir.'/google-v2.db',
      },
   };
}

sub update {
   my $self = shift;

   my $key = $self->key;
   if (! defined($key)) {
      $self->log->error($self->brik_help_set('key'));
      return $self->log->error('See https://developers.google.com/safe-browsing/key_signup');
   }

   my $storage = $self->storage;
   if (! defined($storage)) {
      return $self->log->error($self->brik_help_set('storage'));
   }

   # http://stackoverflow.com/a/5329129
   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

   my $gsb_storage = Net::Google::SafeBrowsing2::Sqlite->new(
      file => $storage,
   );
   my $gsb = Net::Google::SafeBrowsing2->new(
      key => $key,
      storage => $gsb_storage,
      debug => 1,
   );
  
   my $err = {
        -6 => 'DATABASE_RESET',
        -5 => 'MAC_ERROR',
        -4 => 'MAC_KEY_ERROR',
        -3 => 'INTERNAL_ERROR',  # internal/parsing error
        -2 => 'SERVER_ERROR',  # Server sent an error back
        -1 => 'NO_UPDATE',  # no update (too early)
        0 => 'NO_DATA',   # no data sent
        1 => 'SUCCESSFUL',   # data sent
   };

   my $r = $gsb->update;
   $self->log->debug("update: update returned [$r:".$err->{$r}."]");

   return 1;
}

1;

__END__
