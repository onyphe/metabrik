FROM ubuntu:xenial

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
RUN cpanm -n Metabrik
RUN cpanm -n Metabrik::Repository

#
# Update Metabrik to latest head
#
RUN mkdir -p /root/metabrik/brik-tool
RUN perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool","update")'

# Set locale
RUN locale-gen en_GB.UTF-8
RUN update-locale LANG=en_GB.UTF-8

# Initialise the environment
RUN perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("shell::rc", "write_default")'
RUN echo 'use shell::command' >> /root/.metabrik_rc
RUN echo 'use shell::history' >> /root/.metabrik_rc
RUN echo 'use brik::tool' >> /root/.metabrik_rc
RUN echo 'use brik::search' >> /root/.metabrik_rc
RUN echo 'alias ! "run shell::history exec"' >> /root/.metabrik_rc
RUN echo 'alias history "run shell::history show"' >> /root/.metabrik_rc
RUN echo 'set core::shell ps1 docker' >> /root/.metabrik_rc
RUN echo 'alias ls "run shell::command capture ls -Fh"' >> /root/.metabrik_rc
RUN echo 'alias l "run shell::command capture ls -lFh"' >> /root/.metabrik_rc
RUN echo 'alias ll "run shell::command capture ls -lFh"' >> /root/.metabrik_rc

# Install dependencies
#RUN perl -I/root/metabrik/repository/lib -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool", "install_ubuntu_packages")'
#RUN perl -I/root/metabrik/repository/lib -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool", "install_modules")'

CMD ["/usr/local/bin/metabrik.sh"]
