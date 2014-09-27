#
# $Id: Wwwutil.pm 89 2014-09-17 20:29:29Z gomor $
#
# Wwwutil brick
#
package Metabricky::Brick::Http::Wwwutil;
use strict;
use warnings;

use base qw(Metabricky::Brick);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return {
      'Data::Dumper' => [],
      'WWW::Mechanize' => [],
   };
}

sub help {
   return {
      'run:myip' => '',
      'run:nslookup' => '<hostname> [ <nameserver> ]',
      'run:whois' => '<ip|domain>',
   };
}

sub nslookup {
   my $self = shift;
   my ($host, $ns) = @_;

   my $url = 'http://networking.ringofsaturn.com/Tools/nslookup.php?domain=%s&server=%s&querytype=A';

   my $mech = WWW::Mechanize->new;
   $mech->agent_alias('Windows Mozilla');

   $mech->get(sprintf($url, $host, $ns || '8.8.8.8'));
   # XXX: give access to bricks
   #$self->{Metabricky}->{log}->info("HTTP code: ".$mech->status);

   my $html = $mech->content;

   my ($lookup) = $html =~ /.*<PRE>(.*?)<\/PRE>/s;
   if (! $1) {
      $lookup = $html;
   }

   if (! defined($lookup)) {
      return $self->log->error("no return from lookup");
   }

   my $res = _clean_html($lookup);
   print "$res\n";

   return $res;
}

sub whois {
   my $self = shift;
   my ($who) = @_;

   my $urlIpwhois = 'https://apps.db.ripe.net/search/query.html?searchtext=%s&flags=&sources=&grssources=RIPE;AFRINIC;APNIC;ARIN;LACNIC;JPIRR;RADB&inverse=&types=';

   my $urlWhois = 'http://viewdns.info/whois/?domain=%s';

   my $mech = WWW::Mechanize->new;
   $mech->agent_alias('Windows Mozilla');

   my $res;
   if ($who =~ /^\d+\.\d+\.\d+\.\d+$/) {
      $mech->get(sprintf($urlIpwhois, $who));
      #print "[*] Code: ".$mech->status."\n";

      my $html = $mech->content;

      my ($inetnum, $role, $person, $route) = $html =~ /.*<pre>(inetnum:.*?)<\/pre>.*?<pre>(role:.*?)<\/pre>.*?<pre>(person:.*?)<\/pre>.*?<pre>(route:.*?)<\/pre>.*?/s;

      if (! defined($inetnum)) {
         return $self->log->error("no return from lookup");
      }

      print _clean_html($inetnum)."\n\n";
      print _clean_html($role)."\n\n";
      print _clean_html($person)."\n\n";
      print _clean_html($route)."\n";
   }
   else {
      $mech->get(sprintf($urlWhois, $who));
      #print "[*] Code: ".$mech->status."\n";

      my $html = $mech->content;

      #my ($data) = $html =~ /^.*<br>==============<br><br>(Domain Name:.*?)<br><br><\/td><\/tr><tr><\/tr>/s;
      my ($data) = $html =~ /^.*(WHOIS Information for .*?)<br><br><\/td><\/tr><tr><\/tr>/s;

      if (! defined($data)) {
         return $self->log->error("no return from lookup");
      }

      $res = _clean_html($data);
      print "$res\n";
   }

   return $res;
}

sub myip {
   my $self = shift;

   my $url = 'http://ip.nu';

   my $mech = WWW::Mechanize->new;
   $mech->agent_alias('Windows Mozilla');

   $mech->get($url);
   #print "[*] Code: ".$mech->status."\n";

   my $html = $mech->content;
   #print $html."\n";

   my ($ip) = $html =~ /^.*<h2>(\d+\.\d+\.\d+\.\d+)<\/h2>.*$/s;
   if (! $1) {
      $ip = $html;
   }

   print "$ip\n";

   return $ip;
}

sub _clean_html {
   my ($data) = @_;

   $data =~ s/<a href=.*?>(.*?)<\/a>/$1/gs;
   $data =~ s/<br>/\n/gs;
   $data =~ s/<br \/>/\n/gs;

   $data =~ s/\n*$//gs;
   $data =~ s/^\n*//gs;

   return $data;
}

1;

__END__
