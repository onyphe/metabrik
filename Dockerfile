FROM ubuntu:vivid

RUN apt-get -y update

#
# Packages required by Metabrik::Core
#
# Packaged programs
#
RUN apt-get install -y build-essential sudo less cpanminus nvi iputils-ping
#
# Packaged Perl modules
#
RUN apt-get install -y liblexical-persistence-perl liblocal-lib-perl libppi-perl libterm-readline-gnu-perl libnet-pcap-perl libnet-libdnet-perl libnet-libdnet6-perl mercurial libclass-gomor-perl libclass-gomor-perl libdata-dump-perl libppi-perl libexporter-tiny-perl libterm-readline-gnu-perl libfile-homedir-perl libio-all-perl libterm-shell-perl libipc-run3-perl
#
# Unpackaged Perl modules
#
RUN cpanm -n File::Find Term::ANSIColor Module::Reload

#
# Modules optionnally needed by Metabrik::Repository 
#
# Packaged programs
#
RUN apt-get install -y libssl-dev phantomjs rng-tools tcptraceroute nmap python wget unzip aptitude mysql-client scrot dsniff
#
# Packaged Perl modules
#
RUN apt-get install -y libdbi-perl libnet-ssleay-perl libxml-simple-perl libdbd-sqlite3-perl libcrypt-ssleay-perl libnet-openssh-perl libnet-ssh2-perl libdbd-mysql-perl libdatetime-perl libgnupg-interface-perl libxml-libxml-perl
#
# Unpackaged Perl modules
#
RUN cpanm -n IO::Scalar IO::Socket::INET6 IO::Socket::Multicast IO::Socket::SSL LWP::UserAgent Net::CIDR Net::DNS Net::Frame Net::Frame::Dump Net::Frame::Layer::ICMPv4 Net::Frame::Layer::ICMPv6 Net::Frame::Layer::IPv6 Net::Frame::Simple Net::Netmask Net::Nslookup Net::Routing Net::SSL Net::Write Net::Write::Fast NetAddr::IP String::Random Term::ReadPassword Text::CSV_XS URI URI::Escape WWW::Mechanize Net::NBName Net::IPv4Addr Net::SMTP Net::SinFP3 Net::Whois::Raw Net::FTP List::Util Net::IPv6Addr Crypt::Digest Config::Tiny Geo::IP WWW::Mechanize::PhantomJS URI Net::Twitter HTTP::Proxy LWP::Protocol::connect Daemon::Daemonize Search::Elasticsearch Redis Net::Cmd IO::Handle WWW::Splunk MIME::Base64 URI::Escape Net::Server Progress::Any::Output Progress::Any::Output::TermProgressBarColor LWP::UserAgent::ProgressAny Parse::YARA File::Copy

#
# Metabrik itselves
#
RUN mkdir ~/metabrik
RUN hg clone http://trac.metabrik.org/hg/core ~/metabrik/core
RUN hg clone http://trac.metabrik.org/hg/repository ~/metabrik/repository

# Set locale
RUN locale-gen en_GB.UTF-8
RUN update-locale LANG=en_GB.UTF-8

# Install Metabrik
RUN cd ~/metabrik/core && perl Build.PL && ./Build install
RUN cd ~/metabrik/repository && perl Build.PL

CMD ["/usr/local/bin/metabrik.sh"]
