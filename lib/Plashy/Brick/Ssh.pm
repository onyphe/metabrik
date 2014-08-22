#
# $Id$
#
# Ssh plugin
#
package Plashy::Plugin::Ssh;
use strict;
use warnings;

use base qw(Plashy::Plugin);

our @AS = qw(
   banner
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub help {
   print "set ssh banner <string>\n";
   print "\n";
   print "run ssh parsebanner\n";
}

sub parsebanner {
   my $self = shift;

   if (! defined($self->banner)) {
      die($self->help);
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
