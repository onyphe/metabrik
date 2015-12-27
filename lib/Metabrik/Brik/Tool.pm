#
# $Id$
#
# brik::tool Brik
#
package Metabrik::Brik::Tool;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable program) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         repository => [ qw(Repository) ],
      },
      attributes_default => {
         use_pager => 1,
      },
      commands => {
         install_packages => [ ],
         install_needed_packages => [ qw(Brik) ],
         install_modules => [ ],
         create_tool => [ qw(filename.pl Repository|OPTIONAL) ],
         create_brik => [ qw(Brik Repository|OPTIONAL) ],
         update_core => [ ],
         update_repository => [ ],
         test_repository => [ ],
      },
      require_modules => {
         'Metabrik::Devel::Mercurial' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::Perl::Module' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::System::Package' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         repository => $self->global->repository,
      },
   };
}

sub install_packages {
   my $self = shift;

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   if ($sp->is_os_ubuntu) {
      my @programs = qw(
         aptitude
         aircrack-ng
         clamav
         dcfldd
         dsniff
         elasticsearch
         exif
         ffmpeg
         iw
         libexpat-dev
         libmagic-dev
         libmysqlclient-dev
         libpcap-dev
         libssh2-1-dev
         libssl-dev
         libxml2-dev
         mysql-client
         nikto
         nmap
         phantomjs
         python
         python-pip
         reaver
         redis-server
         rng-tools
         scalpel
         scrot
         tcptraceroute
         unzip
         volatility
         wget
      );

      my @modules = qw(
         libnet-libdnet-perl
      );

      $sp->install([ @programs, @modules ]);
   }
   else {
      return $self->log->error("install_packages: sorry, don't know what to do for your OS.\n".
                               "File a complaint to GomoR[at]metabrik.org");
   }

   return 1;
}

sub install_needed_packages {
   my $self = shift;
   my ($brik) = @_;

   my $con = $self->context;

   my $avail = $con->find_available;
   if (! exists($avail->{$brik})) {
      return $self->log->error("install_needed_packages: Brik [$brik] not available");
   }

   my $module = $avail->{$brik};

   my $b = $module->new_from_brik_init_no_checks($self) or return;
   return $b->install;
}

sub install_modules {
   my $self = shift;

   my @modules = qw(
      Config::Tiny
      Crypt::Digest
      Crypt::SSLeay
      Daemon::Daemonize
      DateTime
      DateTime::TimeZone
      DBD::mysql
      DBD::SQLite
      DBI
      File::Copy
      File::MMagic
      File::Path
      File::Spec
      Geo::IP
      GnuPG::Interface
      HTML::Entities
      HTTP::Proxy
      IO::Handle
      IO::Scalar
      IO::Socket::INET6
      IO::Socket::Multicast
      IO::Socket::SSL
      List::Util
      LWP::Protocol::connect
      LWP::UserAgent
      LWP::UserAgent::ProgressAny
      MIME::Base64
      NetAddr::IP
      Net::CIDR
      Net::Cmd
      Net::DNS
      Net::Frame
      Net::Frame::Dump
      Net::Frame::Layer::ICMPv4
      Net::Frame::Layer::ICMPv6
      Net::Frame::Layer::IPv6
      Net::Frame::Simple
      Net::FTP
      Net::IPv4Addr
      Net::IPv6Addr
      Net::Libdnet6
      Net::NBName
      Net::Netmask
      Net::Nslookup
      Net::OpenSSH
      Net::Pcap
      Net::Routing
      Net::Server
      Net::SinFP3
      Net::SMTP
      Net::SSH2
      Net::SSL
      Net::SSLeay
      Net::Twitter
      Net::Whois::Raw
      Net::Write
      Net::Write::Fast
      Parse::YARA
      Progress::Any::Output
      Progress::Any::Output::TermProgressBarColor
      Redis
      Search::Elasticsearch
      String::Random
      Term::ReadPassword
      Text::CSV_XS
      Time::HiRes
      URI
      URI::Escape
      WWW::Mechanize
      WWW::Mechanize::PhantomJS
      WWW::Splunk
      XML::LibXML
      XML::Simple
   );

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   return $pm->install(\@modules);
}

sub create_tool {
   my $self = shift;
   my ($filename, $repository) = @_;

   $repository ||= $self->repository;
   $self->brik_help_run_undef_arg('create_tool', $filename) or return;
   $self->brik_help_run_undef_arg('create_tool', $repository) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   my $data =<<EOF
#!/usr/bin/perl
#
# \$Id\$
#
use strict;
use warnings;

use lib qw($repository/lib);

use Data::Dumper;
use Metabrik::Core::Context;

# Put your Briks here

my \$con = Metabrik::Core::Context->new or die("core::context");

# Init your Briks here
# my \$ft = Metabrik::File::Text->new_from_brik_init(\$con) or die("file::text");

# Put your Tool code here
# \$ft->write("test", "/tmp/test.txt");

exit(0);
EOF
;

   return $ft->write($data, $filename);
}

sub create_brik {
   my $self = shift;
   my ($brik, $repository) = @_;

   $repository ||= $self->repository;
   $self->brik_help_run_undef_arg('create_brik', $brik) or return;
   $self->brik_help_run_undef_arg('create_brik', $repository) or return;

   $brik = lc($brik);
   if ($brik !~ m{^\w+::\w+(::\w+)*$}) {
      return $self->log->error("create_brik: invalid format for Brik [$brik]");
   }

   my @toks = split(/::/, $brik);
   if (@toks < 2) {
      return $self->log->error("create_brik: invalid format for Brik [$brik]");
   }
   for (@toks) {
      $_ = ucfirst($_);
   }

   my $directory;
   if (@toks > 2) {
      $directory = join('/', $repository, 'lib/Metabrik', @toks[0..$#toks-1]);
   }
   else {
      $directory = join('/', $repository, 'lib/Metabrik', $toks[0]);
   }
   my $filename = $directory.'/'.$toks[-1].'.pm';
   my $package = join('::', 'Metabrik', @toks);

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($directory) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   my $data =<<EOF
#
# \$Id\$
#
# $brik Brik
#
package $package;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '\$Revision\$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
      },
      commands => {
      },
      require_modules => {
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

sub brik_use_properties {
   my \$self = shift;

   return {
      attributes_default => {
      },
   };
}

sub brik_preinit {
   my \$self = shift;

   # Do your preinit here, return 0 on error.

   return \$self->SUPER::brik_preinit;
}

sub brik_init {
   my \$self = shift;

   # Do your init here, return 0 on error.

   return \$self->SUPER::brik_init;
}

sub example_command {
   my \$self = shift;
   my (\$arg1, \$arg2) = \@_;

   \$arg2 ||= \$self->arg2;
   \$self->brik_help_run_undef_arg('example_command', \$arg1) or return;
   my \$ref = \$self->brik_help_run_invalid_arg('example_command', \$arg2, 'ARRAY', 'SCALAR')
      or return;

   if (\$ref eq 'ARRAY') {
      # Do your stuff
   }
   else {
      # Do other stuff
   }

   return 1;
}

sub brik_fini {
   my \$self = shift;

   # Do your fini here, return 0 on error.

   return \$self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

$package - $brik Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
EOF
;

   return $ft->write($data, $filename);
}

sub update_core {
   my $self = shift;

   my $datadir = $self->datadir;

   my $url = 'http://trac.metabrik.org/hg/core';

   my $dm = Metabrik::Devel::Mercurial->new_from_brik_init($self) or return;
   $dm->use_pager(0);
   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   $pm->use_pager(0);

   if (! -d $datadir.'/core') {
      $dm->clone($url, $datadir.'/core') or return;
   }
   else {
      $dm->update($datadir.'/core') or return;
   }

   $pm->build($datadir.'/core') or return;
   $pm->clean($datadir.'/core') or return;
   $pm->build($datadir.'/core') or return;
   $pm->test($datadir.'/core') or return;
   $pm->install($datadir.'/core') or return;

   return 1;
}

sub update_repository {
   my $self = shift;

   # If we define the core::global repository Attribute, we use that as 
   # a local repository. We will not install Metabrik::Repository in that case.
   my $datadir = $self->datadir;
   my $repository = $self->global->repository || $datadir.'/repository';

   my $url = 'http://trac.metabrik.org/hg/repository';

   my $dm = Metabrik::Devel::Mercurial->new_from_brik_init($self) or return;
   $dm->use_pager(0);
   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   $pm->use_pager(0);

   if (! -d $repository) {
      $dm->clone($url, $repository) or return;
   }
   else {
      $dm->update($repository) or return;
   }

   $pm->build($repository) or return;
   $pm->clean($repository) or return;
   $pm->build($repository) or return;
   $pm->test($repository) or return;

   # If we define the core::global repository Attribute, we use that as 
   # a local repository. We will not install Metabrik::Repository in that case.
   if (! defined($self->global->repository)) {
      $pm->install($repository) or return;
   }

   $self->execute("cat $repository/UPDATING");

   $self->log->info("update_repository: the file just showed contains information that ".
                    "helps you follow API changes.");
   $self->log->info("Read it here [$repository/UPDATING].");

   return "$repository/UPDATING";
}

sub test_repository {
   my $self = shift;
   my ($repository) = @_;

   $repository ||= $self->repository;
   $self->brik_help_run_undef_arg('test_repository', $repository) or return;

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   $pm->use_pager(0);

   $pm->test($repository) or return;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Brik::Tool - brik::tool Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
