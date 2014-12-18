#
# $Id$
#
# network::whois Brik
#
package Metabrik::Network::Whois;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable whois as country cymru) ],
      attributes => {
         input_whois => [ qw(input_file.whois) ],
         eof => [ qw(0|1) ],
         _read => [ qw(INTERNAL) ],
      },
      attributes_default => {
         eof => 0,
      },
      commands => {
         lookup => [ qw(ipv4_address) ],
         update => [ ],
         whois_next_record => [ qw(file.whois|OPTIONAL) ],
      },
      require_binaries => {
         'dig', => [ ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input_whois => $self->global->datadir."/input_file.whois",
      },
   };
}

sub update {
   my $self = shift;

   my @urls = qw(
      ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
      ftp://ftp.ripe.net/ripe/stats/delegated-ripencc-latest
      ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest
      ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-latest
      ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest
   );

   # ftp://ftp.ripe.net/ripe/dbase/split/ripe.db.inetnum.gz
   my @whois = qw(
      ftp://ftp.ripe.net/ripe/dbase/ripe.db.gz
      ftp://ftp.afrinic.net/dbase/afrinic.db.gz
      ftp://ftp.apnic.net/apnic/whois-data/APNIC/split/apnic.db.inetnum.gz
      http://ftp.apnic.net/apnic/dbase/data/jpnic.db.gz
      http://ftp.apnic.net/apnic/dbase/data/krnic.db.gz
      http://ftp.apnic.net/apnic/dbase/data/twnic.in.gz
      http://ftp.apnic.net/apnic/dbase/data/twnic.pn.gz
   );

   my $www = Metabrik::Client::Www->new_from_brik($self);

   for my $url (@urls, @whois) {
      $self->log->verbose("update: GETing url [$url]");

      my $get = $www->get($url);
      if (! defined($get)) {
         $self->log->warning("update: can't GET file url [$url]");
         next;
      }

      (my $filename = $url) =~ s/^.*\/(.*?)$/$1/;

      my $text = Metabrik::File::Text->new_from_brik($self);
      $text->append(0);
      $text->overwrite(1);
      $text->output($self->global->datadir."/$filename.whois");
      $text->write($get->{body});
   }

   return 1;
}

# http://www.team-cymru.org/Services/ip-to-asn.html
sub lookup {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      return $self->log->error($self->brik_help_run('lookup'));
   }

   my @toks = split('\.', $ip);
   my $rev = join('.', reverse @toks);

   my $cmd = "dig +short $rev.origin.asn.cymru.com TXT";
   my $res = $self->capture($cmd);
   if (! defined($res)) {
      return $self->log->error("lookup: dig failed [$cmd]");
   }

   my $first = $res->[0];
   $self->log->verbose("lookup: line [$first]");
   $first =~ s/^"//;
   $first =~ s/"$//;
   my @values = split(/\s+\|\s+/, $first);

   my $h = {
      raw => $res,
      ip => $ip,
      as => $values[0],
      subnet => $values[1],
      countrycode => $values[2],
      registrar => $values[3],
      date => $values[4],
   };

   return $h;
}

sub whois_next_record {
   my $self = shift;
   my ($input) = @_;

   my $read = $self->_read;
   if (! defined($read)) {
      $input ||= $self->input_whois;
      if (! -f $input) {
         return $self->log->error("read_next_record: file [$input] does not exist");
      }

      $read = Metabrik::File::Read->new_from_brik($self);
      $read->encoding('ascii');
      $read->input($input);
      $read->as_array(1);
      $read->open
         or return $self->log->error("read_next_record: file::read open failed");
      $self->_read($read);
   }

   my $lines = $read->read_until_blank_line;
   if (@$lines == 0) {
      $self->eof(1);
      return {};
   }

   my %record = ();
   for my $line (@$lines) {
      next if ($line =~ /^\s*#/);

      my ($key, $val);
      if ($line =~ /^(.*?)\s*:\s*(.*)$/) {
         $key = $1;
         $val = $2;
      }
      next unless defined($val);

      push @{$record{raw}}, $line;

      $self->debug && $self->log->debug("whois_next_record: key [$key] val[$val]");

      if (! exists($record{$key})) {
         $record{$key} = $val;
      }
      else {
         $record{$key} .= "\n$val";
      }
   }

   return \%record;
}

1;

__END__

=head1 NAME

Metabrik::Network::Whois - network::whois Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
