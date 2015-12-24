#
# $Id$
#
# remote::wmi Brik
#
package Metabrik::Remote::Wmi;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         host => [ qw(host) ],
         user => [ qw(username) ],
         password => [ qw(password) ],
      },
      commands => {
         install => [ ],
         request => [ qw(query host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         get_win32_operatingsystem => [ qw(host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         get_win32_process => [ qw(host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         execute => [ qw(command host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'tar' => [ ],
         'wmic' => [ ],
         'winexe' => [ ],
      },
      need_packages => {
         'ubuntu' => [ qw(build-essential autoconf) ],
      },
   };
}

#
# Compilation process
# http://techedemic.com/2014/09/17/installing-wmic-in-ubuntu-14-04-lts-64-bit/
# http://wiki.monitoring-fr.org/nagios/windows-client/superivision-wmi
#
sub install {
   my $self = shift;

   # Install needed packages
   $self->SUPER::install() or return;

   my $datadir = $self->datadir;

   my $version = '1.3.14';

   #my $url = 'http://dev.zenoss.org/svn/trunk/inst/externallibs/wmi-'.$version.'.tar.bz2';
   my $url = 'http://www.openvas.org/download/wmi/wmi-'.$version.'.tar.bz2';
   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $files = $cw->mirror($url, "wmi-$version.tar.bz2", $datadir) or return;

   if (@$files > 0) {
      my $cmd = "tar jxvf $datadir/wmi-$version.tar.bz2 -C $datadir/";
      $self->execute($cmd) or return;
   }

   # cd wmi-1.3.11/Samba/source
   # ./autogen.sh
   # ./configure
   # make proto bin/wmic

   # cd wmi-$version
   # vi GNUmakefile
   # ZENHOME=../..   # Add to beginning of file
   # make "CPP=gcc -E -ffreestanding"

   #my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   #$sf->copy("$datadir/wmi-$version/Samba/source/bin/wmic", "$datadir/") or return;

   return 1;
}

#
# Must add specific user everywhere
#
# Howto enable WMI on a Windows machine
# http://community.zenoss.org/docs/DOC-4517
#
# Troubleshoot WMI connexion issues:
# wbemtest.exe + https://msdn.microsoft.com/en-us/library/windows/desktop/aa394603(v=vs.85).aspx
#
# dcomcnfg => DCOM permission for user
# Computer/Manage/Properties => 'WMI Control/Properties/Security'
#
# Open firewall for DCOM service
# http://www.returnbooleantrue.com/2014/10/enabling-wmi-on-windows-azure.html
#
sub request {
   my $self = shift;
   my ($query, $host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('request', $host) or return;
   $self->brik_help_run_undef_arg('request', $query) or return;
   $self->brik_help_run_undef_arg('request', $user) or return;
   $self->brik_help_run_undef_arg('request', $password) or return;

   my $cmd = "wmic -U$user".'%'."$password //$host \"$query\"";

   return $self->execute($cmd);
}

#
# More requests:
# http://wiki.monitoring-fr.org/nagios/windows-client/superivision-wmi
#
sub get_win32_operatingsystem {
   my $self = shift;

   return $self->request('SELECT * FROM Win32_OperatingSystem', @_);
}

sub get_win32_process {
   my $self = shift;

   return $self->request('SELECT * FROM Win32_Process', @_);
}

#
# 1. Add LocalAccountTokenFilterPolicy registry key
#
# - Click start 
# - Type: regedit 
# - Press enter 
# - In the left, browse to the following folder: 
# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system\ 
# - Right-click a blank area in the right pane 
# - Click New 
# - Click DWORD Value 
# - Type: LocalAccountTokenFilterPolicy 
# - Double-click the item you just created 
# - Type 1 into the box 
# - Click OK 
#
# 2. Add winexesvc service
# runas administrator a cmd.exe
# C:\> sc create winexesvc binPath= C:\WINDOWS\WINEXESVC.EXE start= auto DisplayName= winexesvc 
# C:\> sc description winexesvc "Remote command provider for Zenoss monitoring"
#
sub execute {
   my $self = shift;
   my ($command, $host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('execute', $host) or return;
   $self->brik_help_run_undef_arg('execute', $command) or return;
   $self->brik_help_run_undef_arg('execute', $user) or return;
   $self->brik_help_run_undef_arg('execute', $password) or return;

   my $cmd = "winexe -U$user".'%'."$password //$host \"$command\"";

   return $self->SUPER::execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Remote::Wmi - remote::wmi Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
