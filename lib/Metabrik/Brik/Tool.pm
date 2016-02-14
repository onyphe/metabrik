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
         get_require_modules => [ qw(Brik|OPTIONAL) ],
         get_require_modules_recursive => [ qw(Brik) ],
         get_need_packages => [ qw(Brik|OPTIONAL) ],
         get_need_packages_recursive => [ qw(Brik) ],
         get_brik_hierarchy => [ qw(Brik) ],
         install_all_require_modules => [ ],
         install_all_need_packages => [ ],
         install_needed_packages => [ qw(Brik) ],
         install_required_modules => [ qw(Brik) ],
         create_tool => [ qw(filename.pl Repository|OPTIONAL) ],
         create_brik => [ qw(Brik Repository|OPTIONAL) ],
         update_core => [ ],
         update_repository => [ ],
         test_repository => [ ],
         view_brik_source => [ qw(Brik) ],
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

sub get_require_modules {
   my $self = shift;
   my ($brik) = @_;

   my $con = $self->context;

   my $available = $con->available;

   # If we asked for one Brik, we rewrite available to only have this one.
   if (defined($brik)) {
      $available = { $brik => $available->{$brik} };
   }

   my %modules = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      if (exists($available->{$this}->brik_properties->{require_modules})) {
         my $list = $available->{$this}->brik_properties->{require_modules};
         for my $m (keys %$list) {
            next if $m =~ m{^Metabrik::};
            $modules{$m}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %modules ];
}

sub get_require_modules_recursive {
   my $self = shift;
   my ($brik) = @_;

   # We force to use only one Brik, cause recursion on all Briks takes a too long time.
   $self->brik_help_run_undef_arg('get_require_modules_recursive', $brik) or return;

   my $con = $self->context;
   my $available = $con->available;

   my $list = $self->get_brik_hierarchy($brik) or return;
   my $new = { $brik => $available->{$brik} };  # Don't forget myself
   for my $this (@$list) {
      $new->{$this} = $available->{$this};
   }
   $available = $new;

   my %modules = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      #print "available [$this]\n";
      if (exists($available->{$this}->brik_properties->{require_modules})) {
         my $list = $available->{$this}->brik_properties->{require_modules};
         for my $m (keys %$list) {
            if ($m =~ m{^Metabrik::}) {
               (my $name = $m) =~ s/^Metabrik:://;
               $name = lc($name);
               #print "BRIK [$name]\n";
               my $new = $self->get_require_modules($name);
               for (@$new) {
                  #print "new [$_] for [$name]\n";
                  $modules{$_}++;
               }
            }
            else {
               #print "module [$m]\n";
               $modules{$m}++;
            }
         }
      }
   }

   return [ sort { $a cmp $b } keys %modules ];
}

sub get_need_packages {
   my $self = shift;
   my ($brik) = @_;

   my $con = $self->context;

   my $available = $con->available;

   # If we asked for one Brik, we rewrite available to only have this one.
   if (defined($brik)) {
      $available = { $brik => $available->{$brik} };
   }

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   my $os = $sp->my_os or return;

   my %packages = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      if (exists($available->{$this}->brik_properties->{need_packages})) {
         my $list = $available->{$this}->brik_properties->{need_packages}{$os} or next;
         for my $p (@$list) {
            $packages{$p}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %packages ];
}

sub get_need_packages_recursive {
   my $self = shift;
   my ($brik) = @_;

   # We force to use only one Brik, cause recursion on all Briks takes a too long time.
   $self->brik_help_run_undef_arg('get_need_packages_recursive', $brik) or return;

   my $con = $self->context;
   my $available = $con->available;

   my $list = $self->get_brik_hierarchy($brik) or return;
   my $new = { $brik => $available->{$brik} };  # Don't forget myself
   for my $this (@$list) {
      $new->{$this} = $available->{$this};
   }
   $available = $new;

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   my $os = $sp->my_os or return;

   my %packages = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      if (exists($available->{$this}->brik_properties->{need_packages})) {
         my $list = $available->{$this}->brik_properties->{need_packages}{$os} or next;
         for my $p (@$list) {
            $packages{$p}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %packages ];
}

sub get_brik_hierarchy {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('get_brik_hierarchy', $brik) or return;

   my @toks = split(/::/, $brik);
   if (@toks < 2) {
      return $self->log->error("get_brik_hierarchy: invalid Brik format for [$brik]");
   }

   my @final = ();

   my $m = 'Metabrik';
   for (@toks) {
      $_ = ucfirst($_);
      $m .= "::$_";
   }
   {
      no strict 'refs';
      my @isa = @{$m.'::ISA'};
      for (@isa) {
         next unless /^Metabrik::/;
         (my $name = $_) =~ s/^Metabrik:://;
         $name = lc($name);
         push @final, $name;
         my $list = $self->get_brik_hierarchy($name) or next;
         push @final, @$list;
      }
   }

   return \@final;
}

sub install_all_need_packages {
   my $self = shift;

   # We don't want to fail on a missing package, so we install Brik by Brik
   #my $packages = $self->get_need_packages or return;
   #my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   #return $sp->install($packages);

   my $con = $self->context;

   my @missing = ();
   my $available = $con->available;
   for my $brik (sort { $a cmp $b } keys %$available) {
      # Skipping log modules to avoid messing stuff
      next if ($brik =~ /^log::/);
      # Skipping system packages modules too
      next if ($brik =~ /^system::.*(?:::)?package$/);
      $self->log->verbose("install_all_need_packages: installing packages for Brik [$brik]");
      my $r = $self->install_needed_packages($brik);
      if (! defined($r)) {
         push @missing, $brik;
      }
   }

   if (@missing > 0) {
      return $self->log->error("install_all_need_packages: unable to install packages for ".
         "Brik(s): [".join(', ', @missing)."]");
   }

   return 1;
}

sub install_all_require_modules {
   my $self = shift;

   my $modules = $self->get_require_modules or return;

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   return $pm->install($modules);
}

sub install_needed_packages {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('install_needed_packages', $brik) or return;

   my $packages = $self->get_need_packages_recursive($brik) or return;
   if (@$packages == 0) {
      return 1;
   }

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   return $sp->install($packages);
}

sub install_required_modules {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('install_required_modules', $brik) or return;

   my $modules = $self->get_require_modules_recursive($brik) or return;
   if (@$modules == 0) {
      return 1;
   }

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   return $pm->install($modules);
}

sub create_tool {
   my $self = shift;
   my ($filename, $repository) = @_;

   $repository ||= $self->repository;
   $self->brik_help_run_undef_arg('create_tool', $filename) or return;
   $self->brik_help_run_undef_arg('create_tool', $repository) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   my $data =<<EOF
#!/usr/bin/env perl
#
# \$Id\$
#
use strict;
use warnings;

# Uncomment to use a custom repository
#use lib qw($repository/lib);

use Data::Dumper;
use Metabrik::Core::Context;
# Put other Briks to use here
# use Metabrik::File::Text;

my \$con = Metabrik::Core::Context->new or die("core::context");

# Init other Briks here
# my \$ft = Metabrik::File::Text->new_from_brik_init(\$con) or die("file::text");

# Put Metatool code here
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

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

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
         install => [ ],  # Inherited
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

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

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

   my $url = 'https://www.metabrik.org/hg/core';

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

   my $url = 'https://www.metabrik.org/hg/repository';

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

sub view_brik_source {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('view_brik_source', $brik) or return;

   my @toks = split(/::/, $brik);
   if (@toks < 2) {
      return $self->log->error("view_brik_source: invalid Brik format for [$brik]");
   }

   my $pager = $ENV{PAGER} || 'less';

   my $pm = 'Metabrik';
   for (@toks) {
      $_ = ucfirst($_);
      $pm .= "/$_";
   }
   $pm .= '.pm';

   my $cmd = '';
   for (@INC) {
      if (-f "$_/$pm") {
         $cmd = "$pager $_/$pm";
         last;
      }
   }

   if (length($cmd) == 0) {
      return $self->log->error("view_brik_source: unable to find Brik [$brik] in \@INC");
   }

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Brik::Tool - brik::tool Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
