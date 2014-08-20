#
# $Id$
#
# Global plugin
#
package Plashy::Plugin::Global;
use strict;
use warnings;

use base qw(Plashy::Plugin);

our @AS = qw(
   echo
   input
   output
   db
   file
   uri
   target
   log
   set
   available
   loaded
   not_loaded
   ctimeout
   rtimeout
   commands
   datadir
   plashy
   shell
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use File::Find;

sub new {
   my $self = shift->SUPER::new(
      echo => 0,
      set => {},
      loaded => {},
      available => {},
      datadir => '/tmp',
      @_,
   );

   $self->update_available_plugins;

   return $self;
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $loaded = $self->loaded;
   $loaded->{global} = $self;
   $self->loaded($loaded);

   return $self;
}

sub help {
   print "set global input <input>\n";
   print "set global output <output>\n";
   print "set global commands <commands>\n";
   print "set global db <db>\n";
   print "set global file <file>\n";
   print "set global uri <uri>\n";
   print "set global target <ip|hostname>\n";
   print "set global log <log>\n";
   print "set global ctimeout <seconds>\n";
   print "set global rtimeout <seconds>\n";
   print "\n";
   print "run global load <plugin>\n";
}

sub load {
   my $self = shift;
   my ($plugin) = @_;

   # XXX: use Module::Loaded (core) or Module::Load/Unload or Module::Reload?

   if (! defined($plugin)) {
      die("set global load <plugin>\n");
   }

   my $module = $plugin;
   $module = ucfirst($module);
   $module =~ s/^/Plashy::Plugin::/;

   if (exists($self->loaded->{$plugin})) {
      die("Plugin [$plugin] already loaded\n");
   }

   eval("use $module");
   if ($@) {
      die("unable to load Plugin [$plugin]: $@\n");
   }

   my $new = $module->new(
      global => $self,
   );
   #$new->init; # No init now. We wait first run()

   my $loaded = $self->loaded;
   $loaded->{$plugin} = $new;
   $self->loaded($loaded);

   return $self;
}

my @available = ();

sub _find_plugins {
   if ($File::Find::dir =~ /Plashy\/Plugin$/ && /.pm$/) {
      (my $plugin = lc($_)) =~ s/.pm$//;
      push @available, $plugin;
   }
}

sub update_available_plugins {
   my $self = shift;

   {
      no warnings 'File::Find';
      find(\&_find_plugins, @INC);
   };

   my %h = map { $_ => 1 } @available;

   return $self->available(\%h);
}

1;

__END__
