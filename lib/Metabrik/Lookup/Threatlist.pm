#
# $Id$
#
# lookup::threatlist Brik
#
package Metabrik::Lookup::Threatlist;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable lookup ipv4 ipv6 ip threat threatlist) ],
      attributes => {
         datadir => [ qw(datadir) ],
      },
      commands => {
         update => [ ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my %mirror = (
      'iblocklist-tgbankumtwtrzllndbmb.gz' => 'http://list.iblocklist.com/?list=logmein',
      'iblocklist-nzldzlpkgrcncdomnttb.gz' => 'http://list.iblocklist.com/?list=nzldzlpkgrcncdomnttb',
      'iblocklist-xoebmbyexwuiogmbyprb.gz' => 'http://list.iblocklist.com/?list=bt_proxy',
      'iblocklist-zfucwtjkfwkalytktyiw.gz' => 'http://list.iblocklist.com/?list=zfucwtjkfwkalytktyiw',
      'iblocklist-llvtlsjyoyiczbkjsxpf.gz' => 'http://list.iblocklist.com/?list=bt_spyware',
      'iblocklist-togdoptykrlolpddwbvz.gz' => 'http://list.iblocklist.com/?list=tor',
      'iblocklist-ghlzqtqxnzctvvajwwag.gz' => 'http://list.iblocklist.com/?list=ghlzqtqxnzctvvajwwag',
      'sans-block.txt' => 'http://isc.sans.edu/block.txt',
      'malwaredomains-domains.txt' => 'http://mirror1.malwaredomains.com/files/domains.txt',
      'emergingthreats-compromised-ips.txt.gz' => 'http://rules.emergingthreats.net/blockrules/compromised-ips.txt',
      'emergingthreats-emerging-Block-IPs.txt.gz' => 'http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt',
      'phishtank-verified_online.csv.gz' => 'http://data.phishtank.com/data/online-valid.csv.gz',
      'abusech-palevotracker.txt.gz' => 'https://palevotracker.abuse.ch/blocklists.php?download=ipblocklist',
      'abusech-spyeyetracker.txt.gz' => 'https://spyeyetracker.abuse.ch/blocklist.php?download=ipblocklist',
      'abusech-zeustracker-badips.txt.gz' => 'https://zeustracker.abuse.ch/blocklist.php?download=badips',
      'abusech-zeustracker.txt.gz' => 'https://zeustracker.abuse.ch/blocklist.php?download=ipblocklist',
      'amazonaws-top-1m.csv.zip' => 'http://s3.amazonaws.com/alexa-static/top-1m.csv.zip',
      'iana-tlds-alpha-by-domain.txt' => 'http://data.iana.org/TLD/tlds-alpha-by-domain.txt',
      'publicsuffix-effective_tld_names.dat.gz' => 'https://publicsuffix.org/list/effective_tld_names.dat',
   );

   # IP Threatlist:
   # "abusech-palevotracker.txt",  # Palevo C&C
   # "abusech-zeustracker-badips.txt", # Zeus IPs
   # "abusech-zeustracker.txt", # Zeus IPs
   # "emergingthreats-compromised-ips.txt", # Compromised IPs
   # "emergingthreats-emerging-Block-IPs.txt", # Raw IPs from Spamhaus, DShield and Abuse.ch
   # "iblocklist-ghlzqtqxnzctvvajwwag", # Various exploiters, scanner, spammers IPs
   # "iblocklist-llvtlsjyoyiczbkjsxpf", # Various evil IPs (?)
   # "iblocklist-xoebmbyexwuiogmbyprb", # Proxy and TOR IPs
   # "sans-block.txt", # IP ranges to block for abuse reasons

   # Owner lists
   # "iblocklist-nzldzlpkgrcncdomnttb", # ThePirateBay
   # "iblocklist-togdoptykrlolpddwbvz", # TOR IPs
   # "iblocklist-tgbankumtwtrzllndbmb", # LogMeIn IPs
   # "iblocklist-zfucwtjkfwkalytktyiw", # RapidShare IPs
   # "phishtank-verified_online.csv", # URLs hosting phishings
   # "malwaredomains-domains.txt", # Malware domains

   # Other lists
   # "top-1m.csv",
   # "iana-tlds-alpha-by-domain.txt",
   # "publicsuffix-effective_tld_names.dat",

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->user_agent("Metabrik-Lookup-Threatlist-mirror/1.00");
   $cw->datadir($datadir);

   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   $fc->datadir($datadir);

   for my $f (keys %mirror) {
      my $files = $cw->mirror($mirror{$f}, $f) or next;
      for my $file (@$files) {
         if ($file =~ /\.gz$/) {
            (my $outfile = $file) =~ s/\.gz$//;
            $fc->uncompress($datadir.'/'.$file, $outfile);
         }
         elsif ($file =~ /\.zip$/) {
            (my $outfile = $file) =~ s/\.zip$//;
            $fc->uncompress($datadir.'/'.$file, $outfile);
         }
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Threatlist - lookup::threatlist Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
