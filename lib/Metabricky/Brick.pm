#
# $Id: Brick.pm 93 2014-09-18 06:06:28Z gomor $
#
package Metabricky::Brick;
use strict;
use warnings;

use base qw(Class::Gomor::Hash);

our @AS = qw(
   debug
   inited
   bricks
   log
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub help {
   return {
      'run:help' => '',
      'run:help_set' => '<attribute>',
      'run:help_run' => '<command>',
      'run:commands' => '',
      'run:attributes' => '',
      'run:revision' => '',
      'run:version' => '',
      'run:default_values' => '',
      'run:name' => '',
      'run:repository' => '',
      'run:category' => '',
      'run:commands' => '',
      'run:has_command' => '',
      'run:attributes' => '',
      'run:has_attribute' => '',
      'run:self' => '',
   };
}

sub help_set {
   my $self = shift;
   my ($attribute) = @_;

   my $name = $self->name;

   if (! defined($attribute)) {
      return $self->log->info("run $name help_set <attribute>");
   }

   if (exists($self->help->{"set:$attribute"})) {
      my $help = $self->help->{"set:$attribute"};
      return "set $name $attribute $help";
   }

   $self->log->info("help_set: no help for Brick [$name] with Attribute [$attribute]");
   return '';
}

sub help_run {
   my $self = shift;
   my ($command) = @_;

   my $name = $self->name;

   if (! defined($command)) {
      return $self->log->info("run $name help_run <command>");
   }

   if (exists($self->help->{"run:$command"})) {
      my $help = $self->help->{"run:$command"};
      return "run $name $command $help";
   }

   $self->log->info("help_run: no help for Brick [$name] with Command [$command]");
   return '';
}

sub new {
   my $self = shift->SUPER::new(
      debug => 0,
      inited => 0,
      @_,
   );

   my $default_values = $self->default_values;
   for my $k (keys %$default_values) {
      $self->$k($default_values->{$k});
   }

   my $modules = $self->require_modules;
   for my $module (@$modules) {
      eval("use $module");
      if ($@) {
         chomp($@);
         return $self->log->error("new: you have to install Module [$module]");
      }
   }

   return $self;
}

sub revision {
   return 1;
}

sub version {
   my $self = shift;

   my $revision = $self->revision;
   my ($version) = $revision =~ /(\d+)/;

   # Version 1 of the API
   return "1.$version";
}

sub default_values {
   return {
      debug => 0,
      inited => 0,
      bricks => {},
   };
}

sub name {
   my $self = shift;

   my $module = lc(ref($self));
   $module =~ s/^metabricky::brick:://;

   return $module;
}

sub repository {
   my $self = shift;

   my $name = $self->name;

   my @toks = split('::', $name);

   # No repository defined
   if (@toks == 2) {
      return 'main';
   }
   elsif (@toks > 2) {
      my ($repository) = $name =~ /^(.*?)::.*/;
      return $repository;
   }

   return $self->log->fatal("repository: no Repository found");
}

sub category {
   my $self = shift;

   my $name = $self->name;

   my @toks = split('::', $name);

   # No repository defined
   if (@toks == 2) {
      my ($category) = $name =~ /^(.*?)::.*/;
      return $category;
   }
   elsif (@toks > 2) {
      my ($category) = $name =~ /^.*?::(.*?)::.*/;
      return $category;
   }

   # Error, category not found
   return $self->log->fatal("category: no Category found");
}

sub commands {
   my $self = shift;

   my $object = ref($self);
   my $ary = [ $object ];
   $object->cgGetIsaTree($ary);

   my %commands = ();

   for my $class (@$ary) {
      next if ($class !~ /^Metabricky::Brick/ || ! $class->can('help'));

      my $help = $class->help;

      for my $this (keys %$help) {
         my ($command, $name) = split(':', $this);

         next unless $name =~ /^[a-z]/; # Brick Commands always begin with a minuscule
         next if $name =~ /^cg[A-Z]/; # Class::Gomor stuff
         next if $name =~ /^_/; # Internal stuff
         next if $name =~ /^(?:a|b|import|init|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff

         if ($command eq 'set' || $command eq 'run') {
            $commands{$name}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %commands ];
}

sub has_command {
   my $self = shift;
   my ($command) = @_;

   if (! defined($command)) {
      return $self->log->info("run ".ref($self)." has_command <command>");
   }

   if ($self->can($command)) {
      return 1;
   }

   return;
}

sub attributes {
   my $self = shift;

   my $object = ref($self);
   my $ary = [ $object ];
   $object->cgGetIsaTree($ary);

   my %attributes = ();

   for my $class (@$ary) {
      next if ($class !~ /^Metabricky::Brick/ || ! $class->can('help'));

      my $help = $class->help;

      for my $this (keys %$help) {
         my ($command, $name) = split(':', $this);

         next unless $name =~ /^[a-z]/; # Brick Attributes always begin with a minuscule
         next if $name =~ /^_/; # Internal stuff

         if ($command eq 'set') {
            $attributes{$name}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %attributes ];
}

sub has_attribute {
   my $self = shift; 
   my ($attribute) = @_;

   if (! defined($attribute)) {
      return $self->log->info("run ".ref($self)." has_attribute <command>");
   }

   if ($self->can($attribute)) {
      return 1;
   }

   return;
}

sub init {
   my $self = shift;

   if ($self->inited) {
      return;
   }

   $self->inited(1);

   return $self;
}

sub require_modules {
   return [];
}

sub self {
   my $self = shift;

   return $self;
}

sub DESTROY {
   my $self = shift;

   return $self;
}

1;

__END__
