#
# $Id$
#
# network::nikto Brik
#
package Metabrik::Network::Nikto;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network security scanner nikto) ],
      attributes => {
         datadir => [ qw(datadir) ],
         uri => [ qw(uri) ],
         args => [ qw(nikto_arguments) ],
         output => [ qw(output_file.html) ],
      },
      attributes_default => {
         uri => 'http://127.0.0.1/',
         args => '-Display V -Format html',
         output => 'last.html',
      },
      commands => {
         start => [ qw(uri|OPTIONAL) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->global->datadir.'/network-nikto';

   return {
      attributes_default => {
         datadir => $datadir,
      },
   };
}

sub brik_init {
   my $self = shift;

   my $dir = $self->datadir;
   if (! -d $dir) {
      mkdir($dir)
         or return $self->log->error("brik_init: mkdir failed for dir [$dir]");
   }

   return $self->SUPER::brik_init(@_);
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
   my ($uri, $output) = @_;

   $output ||= $self->output;
   $uri ||= $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   my $target = Metabrik::String::Uri->new_from_brik($self);
   my $p = $target->parse($uri);

   my $host = $p->{host};
   my $port = $p->{port};
   my $path = $p->{path};
   my $use_ssl = $target->is_https_scheme($p);

   my $args = $self->args;

   my $datadir = $self->datadir;
 
   my $cmd = "nikto -host $host -port $port -root $path $args";
   if ($use_ssl) {
      $cmd .= " -ssl";
   }

   $cmd .= " -output $datadir/$output 2>&1 | tee $datadir/$output.txt";

   my $result = `$cmd`; 

   my $parsed = $self->_nikto_parse($cmd, $result);

   return $parsed;
}

1;

__END__

=head1 NAME

Metabrik::Network::Nikto - network::nikto Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
