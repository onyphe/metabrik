#
# $Id$
#
# scanner::nikto Brik
#
package Metabrik::Scanner::Nikto;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable scanner nikto) ],
      attributes => {
         target => [ qw(target) ],
         path => [ qw(url_path) ],
         port => [ qw(integer) ],
         args => [ qw(nikto_arguments) ],
         save_output => [ qw(0|1) ],
         use_ssl => [ qw(0|1) ],
      },
      attributes_default => {
         target => '127.0.0.1',
         port => 80,
         args => '-Display V -Format html',
         save_output => 0,
         use_ssl => 0,
         path => '/',
      },
      commands => {
         start => [ ],
      },
   };
}

sub _nikto_parse {
   my $self = shift;
   my ($cmd, $result) = @_;

   my $parsed = {};

   push @{$parsed->{raw}}, $cmd;

   for (split(/\n/, $result)) {
      push @{$parsed->{raw}}, $_;
   }

   return $parsed;
}

# nikto -host XXX.com -root /XXX -Display V -port 443 -ssl -Format html -output /root/XXX/outil_nikto/XXX_nikto_https.html 2>&1 | tee /root/XXX/outil_nikto/XXX_nikto_https.txt
# nikto -host 127.0.0.1 -port 80 -root /path -Display V -Format html -ssl -output /home/gomor/metabrik/nikto.html
sub start {
   my $self = shift;

   my $args = $self->args;
   my $target = $self->target;
   my $port = $self->port;
   my $save_output = $self->save_output;
   my $path = $self->path;
   my $use_ssl = $self->use_ssl;

   my $datadir = $self->global->datadir;
 
   my $cmd = "nikto -host $target -port $port -root $path $args";
   if ($use_ssl) {
      $cmd .= " -ssl";
   }
   if ($save_output) {
      $cmd .= " -output $datadir/nikto.html";
      $cmd .= ' 2>&1 | tee '."$datadir/nikto.txt";
   }

   my $result = `$cmd`; 

   my $parsed = $self->_nikto_parse($cmd, $result);

   return $parsed;
}

1;

__END__
