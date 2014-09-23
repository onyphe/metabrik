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
   context
   log
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub help {
   return {
      'set:debug' => '<0|1>',
      'set:context' => '<context>',
      'run:help' => '',
      'run:help_set' => '<attribute>',
      'run:help_run' => '<command>',
      'run:class' => '',
      'run:classes' => '',
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
      'run:bricks' => '',
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

   my $classes = $self->classes;

   for my $class (@$classes) {
      last if $class eq 'Metabricky::Brick';

      if (exists($class->help->{"set:$attribute"})) {
         my $help = $class->help->{"set:$attribute"};
         return "set $name $attribute $help";
      }
   }

   return;
}

sub help_run {
   my $self = shift;
   my ($command) = @_;

   my $name = $self->name;

   if (! defined($command)) {
      return $self->log->info("run $name help_run <command>");
   }

   my $classes = $self->classes;

   for my $class (@$classes) {
      last if $class eq 'Metabricky::Brick';

      if (exists($class->help->{"run:$command"})) {
         my $help = $class->help->{"run:$command"};
         return "run $name $command $help";
      }
   }

   return;
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

   # Not all modules are capable of checking context against loaded bricks
   # For instance, core::context Brick itselves.
   if (defined($self->context) && $self->context->can('loaded')) {
      my $error = 0;
      my $loaded = $self->context->loaded;
      my $require_loaded = $self->require_loaded;
      for my $brick (@$require_loaded) {
         if (! $self->context->is_loaded($brick)) {
            $self->log->error("new: you must load Brick [$brick] first");
            $error++;
         }
      }

      if ($error) {
         return;
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

   my $module = lc($self->class);
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

sub class {
   my $self = shift;

   return ref($self) || $self;
}

sub classes {
   my $self = shift;

   my $class = $self->class;
   my $ary = [ $class ];
   $class->cgGetIsaTree($ary);

   my @classes = ();

   for my $class (@$ary) {
      next if ($class !~ /^Metabricky::Brick/);
      push @classes, $class;
   }

   return \@classes;
}

sub commands {
   my $self = shift;

   my %commands = ();

   my $classes = $self->classes;

   for my $class (@$classes) {
      next if (! $class->can('help'));

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
      return $self->log->info("run ".$self->name." has_command <command>");
   }

   if ($self->can($command)) {
      return 1;
   }

   return 0;
}

sub attributes {
   my $self = shift;

   my %attributes = ();

   my $classes = $self->classes;

   for my $class (@$classes) {
      next if (! $class->can('help'));

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
      return $self->log->info("run ".$self->name." has_attribute <command>");
   }

   if ($self->can($attribute)) {
      return 1;
   }

   return 0;
}

sub init {
   my $self = shift;

   if ($self->inited) {
      return;
   }

   $self->inited(1);

   return $self;
}

sub require_loaded {
   return [];
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
