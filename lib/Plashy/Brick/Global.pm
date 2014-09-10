#
# $Id$
#
# Global brick
#
package MetaBricky::Brick::Global;
use strict;
use warnings;

use base qw(MetaBricky::Brick);

our @AS = qw(
   echo
   newline
   input
   output
   db
   file
   uri
   target
   set
   available
   loaded
   not_loaded
   ctimeout
   rtimeout
   commands
   datadir
   shell
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use File::Find;

sub new {
   my $self = shift->SUPER::new(
      echo => 0,
      newline => 0,
      set => {},
      loaded => {},
      available => {},
      datadir => '/tmp',
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
   print "set global echo <1|0>\n";
   print "set global newline <1|0>\n";
   print "set global input <input>\n";
   print "set global output <output>\n";
   print "set global db <db>\n";
   print "set global file <file>\n";
   print "set global uri <uri>\n";
   print "set global target <target>\n";
   print "set global ctimeout <connection_timeout>\n";
   print "set global rtimeout <read_timeout>\n";
   print "set global commands <command1:command2:..:commandN>\n";
   print "set global datadir <directory>\n";
   print "\n";
   print "run global load <brick>\n";
}

sub load {
   my $self = shift;
   my ($brick) = @_;

   # XXX: use Module::Loaded (core) or Module::Load/Unload or Module::Reload?

   if (! defined($brick)) {
      die("set global load <brick>\n");
   }

   my $module = $brick;
   $module = ucfirst($module);
   $module =~ s/^/MetaBricky::Brick::/;

   if (exists($self->loaded->{$brick})) {
      die("Brick [$brick] already loaded\n");
   }

   eval("use $module;");
   if ($@) {
      chomp($@);
      die("unable to load Brick [$brick]: $@\n");
   }

   my $new = $module->new(
      global => $self,
   );
   #$new->init; # No init now. We wait first run()

   my $loaded = $self->loaded;
   $loaded->{$brick} = $new;
   $self->loaded($loaded);

   return $self;
}

my @available = ();

sub _find_bricks {
   if ($File::Find::dir =~ /MetaBricky\/Brick$/ && /.pm$/) {
      (my $brick = lc($_)) =~ s/.pm$//;
      push @available, $brick;
   }
}

sub update_available_bricks {
   my $self = shift;

   {
      no warnings 'File::Find';
      find(\&_find_bricks, @INC);
   };

   my %h = map { $_ => 1 } @available;

   return $self->available(\%h);
}

1;

__END__
