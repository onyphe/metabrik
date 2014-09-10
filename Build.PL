#
# $Id$
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabricky',
   license => 'artistic',
   dist_author => 'GomoR <gomor-cpan_at_gomor.org>',
   dist_version_from => 'lib/Metabricky.pm',
   requires => {
      'Class::Gomor' => '1.00',
      'Cwd' => 0,
      'Data::Dump' => 0,
      'Data::Dumper' => 0,
      'File::HomeDir' => 0,
      'File::Find' => 0,
      'File::Slurp' => 0,
      'HTTP::Proxy' => 0,
      'IO::All' => 0,
      'IO::Socket::SSL' => 0,
      'JSON::XS' => 0,
      'Lexical::Persistence' => 0,
      'LWP::Protocol::connect' => 0,
      'LWP::UserAgent' => 0,
      'Module::Reload' => 0,
      'Net::Frame' => 0,
      'Net::Frame::Device' => 0,
      'Net::Frame::Layer::ETH' => 0,
      'Net::Frame::Layer::ICMPv4' => 0,
      'Net::Frame::Layer::ICMPv6' => 0,
      'Net::Frame::Layer::IPv4' => 0,
      'Net::Frame::Layer::IPv6' => 0,
      'Net::Frame::Layer::TCP' => 0,
      'Net::Frame::Layer::UDP' => 0,
      'Net::NBName' => 0,
      'Net::Netmask' => 0,
      'Net::Server' => 0,
      'Net::SSH2' => 0,
      'Net::SSLeay' => 0,
      'Term::Shell' => 0,
      'URI' => 0,
      'vFeed' => 0,
      'WWW::Mechanize' => 0,
      'XML::Simple' => 0,
   },
);

$builder->create_build_script;
