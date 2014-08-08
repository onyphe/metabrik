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
   input
   output
   db
   file
   uri
   target
   log
   set
   loaded
   ctimeout
   rtimeout
   commands
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      set => {},
      loaded => {},
      @_,
   );

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
      die("You must provide a Plugin argument\n");
   }

   my $module = $plugin;
   $module = ucfirst($module);
   $module =~ s/^/Plashy::Plugin::/;

   if (exists($self->loaded->{$plugin})) {
      die("Plugin $plugin already loaded\n");
   }

   eval("use $module");
   if ($@) {
      die("Unable to load plugin [$plugin]: $@\n");
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

1;

__END__
