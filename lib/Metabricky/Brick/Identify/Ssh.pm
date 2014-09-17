#
# $Id$
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

sub help {
   return [
      'set identify::ssh banner <string>',
      'run identify::ssh parsebanner',
   ];
}

sub parsebanner {
   my $self = shift;

   if (! defined($self->banner)) {
      return $self->log->info("set identify::ssh banner <string>");
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
