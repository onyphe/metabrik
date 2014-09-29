#
# $Id: Ssh.pm 89 2014-09-17 20:29:29Z gomor $
#
# Ssh brick
#
package Metabricky::Brick::Identify::Ssh;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   banner
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub help {
   return {
      'set:banner' => '<string>',
      'run:parsebanner' => '',
   };
}

sub parsebanner {
   my $self = shift;

   if (! defined($self->banner)) {
      return $self->log->info($self->help_set('banner'));
   }

   my $banner = $self->banner;

   # From most specific to less specific
   my $data = [
      [
         '^SSH-(\d+\.\d+)-OpenSSH_(\d+\.\d+\.\d+)(p\d+) Ubuntu-(2ubuntu2)$' => {
            ssh_protocol_version => '$1',
            ssh_product_version => '$2',
            ssh_product_feature_portable => '$3',
            ssh_os_distribution_version => '$4',
            ssh_product => 'OpenSSH',
            ssh_os => 'Linux',
            ssh_os_distribution => 'Ubuntu',
         },
      ],
      [
         '^SSH-(\d+\.\d+)-OpenSSH_(\d+\.\d+)_(\S+) (\S+)$' => {
            ssh_protocol_version => '$1',
            ssh_product_version => '$2',
            ssh_product_feature_portable => '$3',
            ssh_product => 'OpenSSH',
            ssh_extra => '$4',
         },
      ],
      [
         '^SSH-(\d+\.\d+)(.*)$' => {
            ssh_protocol_version => '$1',
            ssh_product => 'UNKNOWN',
            ssh_extra => '$2',
         },
      ],
   ];

   my $result = {};
   for my $elt (@$data) {
      my $re = $elt->[0];
      my $info = $elt->[1];
      if ($banner =~ /$re/) {
         for my $k (keys %$info) {
            $result->{$k} = eval($info->{$k}) || $info->{$k};
         }
         last;
      }
   }

   return $result;
}

1;

__END__
