#
# $Id$
#
package MetaBricky::Ext::Utils;
use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw(
   peu_convert_path
);

# Converts Windows path
sub peu_convert_path {
   my ($path) = @_;

   $path =~ s/\\/\//g;

   return $path;
}

1;

__END__
