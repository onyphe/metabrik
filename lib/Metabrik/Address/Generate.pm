#
# $Id$
#
# address::generate Brik
#
package Metabrik::Address::Generate;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable address ipv4 routable reserved) ],
      attributes => {
         output_directory => [ qw(directory) ],
         file_count => [ qw(integer) ],
         ip_count => [ qw(integer) ],
      },
      commands => {
         ipv4_reserved_ranges => [ ],
         ipv4_private_ranges => [ ],
         ipv4_routable_ranges => [ ],
         ipv4_generate_space => [ ],
      },
      require_modules => {
         'List::Util' => [ 'shuffle' ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         output_directory => $self->global->datadir.'/address-generate',
         file_count => 1000,
         ip_count => 0,
      },
   };
}

sub brik_init {
   my $self = shift->SUPER::brik_init(
      @_,
   ) or return 1; # Init already done

   # Increase the max open files limit under Linux
   if ($^O eq 'Linux') {
      `ulimit -n 2048`;
   }

   if (! -d $self->output_directory) {
      mkdir($self->output_directory);
   }

   return $self;
}

sub ipv4_reserved_ranges {
   my $self = shift;

   # http://www.h-online.com/security/services/Reserved-IPv4-addresses-732899.html
   my @reserved = qw(
      0.0.0.0/8
      10.0.0.0/8
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.2.0/24
      192.168.0.0/16
      224.0.0.0/4
      240.0.0.0/4
   );

   return \@reserved;
}

sub ipv4_private_ranges {
   my $self = shift;

   my @private = qw(
      10.0.0.0/8
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.2.0/24
      192.168.0.0/16
   );

   return \@private;
}

sub ipv4_routable_ranges {
   my $self = shift;

   my $reserved = $self->ipv4_reserved_ranges;
   # XXX: to compute, check script at work

   return 1;
}

sub ipv4_generate_space {
   my $self = shift;

   my $output_directory = $self->output_directory;
   my $file_count = $self->file_count;
   my $ip_count = $self->ip_count;

   my $n = $file_count - 1;
   my $count = $ip_count ? $ip_count : undef;

   my @chunks = ();
   my $new;
   if ($n > 0) {
      for (0..$n) {
         my $file = sprintf("ip4-space-%03d.txt", $_);
         open($new, '>', "$output_directory/$file")
            or return $self->log->error("ipv4_generate_space: open: file [$output_directory/$file]: $!");
         push @chunks, $new;
      }
   }
   else {
      my $file = sprintf("ip4-space.txt", $_);
      open($new, '>', "$output_directory/$file")
         or return $self->log->error("ipv4_generate_space: open: file [$output_directory/$file]: $!");
      push @chunks, $new;
   }

   my $current = 0;

   # XXX: may not be the based algorithm when not generating full IPv4 range
   # To skip: $self->ipv4_reserved_ranges
   for my $b1 (List::Util::shuffle(1..9,11..126,128..223)) {  # Skip 0.0.0.0/8, 224.0.0.0/4,
                                                              # 240.0.0.0/4, 10.0.0.0/8,
                                                              # 127.0.0.0/8
      for my $b2 (List::Util::shuffle(0..255)) {
         next if ($b1 == 169 && $b2 == 254);               # Skip 169.254.0.0/16
         next if ($b1 == 172 && ($b2 >= 16 && $b2 <= 31)); # Skip 172.16.0.0/12
         next if ($b1 == 192 && $b2 == 168);               # Skip 192.168.0.0/16
         for my $b3 (List::Util::shuffle(0..255)) {
            next if ($b1 == 192 && $b2 == 0 && $b3 == 2);  # Skip 192.0.2.0/24
            for my $b4 (List::Util::shuffle(0..255)) {
               my $i;
               if ($n > 0) {
                  $i = int(rand($n + 1));
               }
               else {
                  $i = 0;
               }
               my $out = $chunks[$i];
               print $out "$b1.$b2.$b3.$b4\n";
               $current++;

               # Stop if we have the number we wanted
               return 1 if defined($count) && ($current == $count);
            }
         }
      }
   }

   return 1;
}

1;

__END__
