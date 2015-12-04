FROM ubuntu:vivid

RUN apt-get -y update

#
# Packages required by Metabrik::Core
#
# Packaged programs
#
RUN apt-get install -y build-essential sudo less cpanminus nvi iputils-ping mercurial libreadline-dev
#
# Perl modules
#
RUN cpanm -n Lexical::Persistence PPI Term::ReadLine::Gnu Class::Gomor Data::Dump File::Find Term::ANSIColor Module::Reload Exporter::Tiny File::HomeDir IO::All Term::Shell IPC::Run3

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

# Initialise the environment
RUN perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("shell::rc", "write_default")'

# Install dependencies
RUN perl -I/root/metabrik/repository/lib -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool", "install_ubuntu_packages")'
RUN perl -I/root/metabrik/repository/lib -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool", "install_modules")'

CMD ["/usr/local/bin/metabrik.sh"]
