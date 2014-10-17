#
# $Id$
#
package Metabrik::Brik;
use strict;
use warnings;

use base qw(CPAN::Class::Gomor::Hash);

our @AS = qw(
   debug
   inited
   context
   global
   log
   shell
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Metabrik;

sub brik_version {
   my $self = shift;

   my $revision = $self->brik_properties->{revision};
   $revision =~ s/^.*?(\d+).*?$/$1/;

   return $Metabrik::VERSION.'.'.$revision;
}

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw() ],
      attributes => {
         debug => [ qw(SCALAR) ],
         inited => [ qw(SCALAR) ],
         context => [ qw(OBJECT) ],
         global => [ qw(OBJECT) ],
         log => [ qw(OBJECT) ],
         shell => [ qw(OBJECT) ],
      },
      attributes_default => {
         debug => 0,
         inited => 0,
      },
      commands => {
         brik_version => [ q() ],
         brik_help_set => [ qw(SCALAR) ],
         brik_help_run => [ qw(SCALAR) ],
         brik_class => [ qw() ],
         brik_classes => [ qw() ],
         brik_name => [ qw() ],
         brik_repository => [ qw() ],
         brik_category => [ qw() ],
         brik_tags => [ qw() ],
         brik_has_tag => [ qw(SCALAR) ],
         brik_commands => [ qw() ],
         brik_has_command => [ qw(SCALAR) ],
         brik_attributes => [ qw() ],
         brik_has_attribute => [ qw(SCALAR) ],
         brik_self => [ qw() ],
      },
      require_modules => { },
      require_used => { },
   };
}

sub brik_use_properties {
   return { };
}

sub brik_help_set {
   my $self = shift;
   my ($attribute) = @_;

   my $name = $self->brik_name;

   if (! defined($attribute)) {
      return $self->log->info("run $name brik_help_set <attribute>");
   }

   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      last if $class eq 'Metabrik::Brik';

      my $attributes = $class->brik_attributes;

      if (exists($attributes->{$attribute})) {
         my $help = sprintf("set %s %-20s ", $name, $attribute);
         $help .= join(' ', @{$attributes->{$attribute}});
         return $help;
      }
   }

   return;
}

sub brik_help_run {
   my $self = shift;
   my ($command) = @_;

   my $name = $self->brik_name;

   if (! defined($command)) {
      return $self->log->info("run $name brik_help_run <command>");
   }

   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      last if $class eq 'Metabrik::Brik';

      my $commands = $class->brik_commands;

      if (exists($commands->{$command})) {
         my $help = sprintf("run %s %-20s ", $name, $command);
         $help .= join(' ', @{$commands->{$command}});
         return $help;
      }
   }

   return;
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   if (! $self->can('brik_properties')) {
      return $self->log->error("new: Brik [".$self->brik_name."] has no brik_properties");
   }

   # Build Attributes, Class::Gomor style
   my $attributes = $self->brik_properties->{attributes};
   my @as = ( keys %$attributes );
   if (@as > 0) {
      no strict 'refs';

      my $class = $self->brik_class;

      my %current = map { $_ => 1 } @{$class.'::AS'};
      my @new = ();
      for my $this (@as) {
         if (! exists($current{$this})) {
            push @new, $this;
         }
      }

      push @{$class.'::AS'}, @new;
      for my $this (@new) {
         if (! $class->can($this)) {
            $class->cgBuildAccessorsScalar([ $this ]);
         }
      }
   }

   # Set default values for Attributes
   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      next if (! $class->can('brik_properties'));

      # brik_properties() is the general value to use for the default_attributes
      if (exists($class->brik_properties->{attributes_default})) {
         for my $attribute (keys %{$class->brik_properties->{attributes_default}}) {
            #next unless defined($self->$attribute); # Do not overwrite if set on new
            $self->$attribute($class->brik_properties->{attributes_default}->{$attribute});
         }
      }

      last if $class eq 'Metabrik::Brik';
   }

   # Then we look at standard default attributes
   if ($self->can('brik_use_properties') && exists($self->brik_use_properties->{attributes_default})) {
      for my $attribute (keys %{$self->brik_use_properties->{attributes_default}}) {
         #next unless defined($self->$attribute); # Do not overwrite if set on new
         $self->$attribute($self->brik_use_properties->{attributes_default}->{$attribute});
      }
   }

   # Module check
   my $modules = $self->brik_properties->{require_modules};
   for my $module (keys %$modules) {
      eval("require $module;");
      if ($@) {
         chomp($@);
         return $self->log->error("new: you have to install Module [$module]: $@", $self->brik_class);
      }

      my @imports = @{$modules->{$module}};
      if (@imports > 0) {
         eval('$module->import(@imports);');
         if ($@) {
            chomp($@);
            return $self->log->error("new: unable to import Functions [@imports] ".
               "from Module [$module]: $@", $self->brik_class
            );
         }
      }
   }

   # Not all modules are capable of checking context against used briks
   # For instance, core::context Brik itselves.
   if (defined($self->context) && $self->context->can('used')) {
      my $error = 0;
      my $used = $self->context->used;
      my $require_used = $self->brik_properties->{require_used};
      for my $brik (keys %$require_used) {
         if (! $self->context->is_used($brik)) {
            $self->log->error("new: you must use Brik [$brik] first", $self->brik_class);
            $error++;
         }
      }

      if ($error) {
         return;
      }
   }

   return $self->brik_preinit;
}

sub brik_repository {
   my $self = shift;

   my $name = $self->brik_name;

   my @toks = split('::', $name);

   # No repository defined
   if (@toks == 2) {
      return 'main';
   }
   elsif (@toks > 2) {
      my ($repository) = $name =~ /^(.*?)::.*/;
      return $repository;
   }

   return $self->log->fatal("brik_repository: no Repository found");
}

sub brik_category {
   my $self = shift;

   my $name = $self->brik_name;

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
   return $self->log->fatal("brik_category: no Category found");
}

sub brik_name {
   my $self = shift;

   my $module = lc($self->brik_class);
   $module =~ s/^metabrik::brik:://;

   return $module;
}

sub brik_class {
   my $self = shift;

   return ref($self) || $self;
}

sub brik_classes {
   my $self = shift;

   my $class = $self->brik_class;
   my $ary = [ $class ];
   $class->cgGetIsaTree($ary);

   my @classes = ();

   for my $class (@$ary) {
      next if ($class !~ /^Metabrik::Brik/);
      push @classes, $class;
   }

   return \@classes;
}

sub brik_tags {
   my $self = shift;

   my $tags = $self->brik_properties->{tags};

   # We add the used tags if Brik has been used.
   # Not all Briks have a context set (core::context don't)
   if ($self->brik_category eq 'core' || ($self->can('context') && $self->context->is_used($self->brik_name))) {
      push @$tags, 'used';
   }
   else {
      push @$tags, 'not_used';
   }

   return [ sort { $a cmp $b } @$tags ];
}

sub brik_has_tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($tag)) {
      return $self->log->info("run ".$self->brik_name." brik_has_tag <tag>");
   }

   my %h = map { $_ => 1 } @{$self->brik_tags};

   if (exists($h{$tag})) {
      return 1;
   }

   return 0;
}

sub brik_commands {
   my $self = shift;

   my $commands = { };

   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      next if (! $class->can('brik_properties'));

      #$self->log->info("brik_commands: class[$class]");

      if (exists($class->brik_properties->{commands})) {
         for my $command (keys %{$class->brik_properties->{commands}}) {
            next unless $command =~ /^[a-z]/; # Brik Commands always begin with a minuscule
            next if $command =~ /^cg[A-Z]/; # Class::Gomor stuff
            next if $command =~ /^_/; # Internal stuff
            next if $command =~ /^(?:a|b|import|brik_init|brik_preinit|brik_fini|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff

            #$self->log->info("command[$command]");
            $commands->{$command} = $class->brik_properties->{commands}->{$command};
         }
      }

      last if $class eq 'Metabrik::Brik';
   }

   return $commands;
}

sub brik_has_command {
   my $self = shift;
   my ($command) = @_;

   if (! defined($command)) {
      return $self->log->info($self->brik_help_run('brik_has_command'));
   }

   if (exists($self->brik_commands->{$command})) {
      return 1;
   }

   return 0;
}

sub brik_attributes {
   my $self = shift;

   my $attributes = { };

   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      next if (! $class->can('brik_properties'));

      #$self->log->info("brik_attributes: class[$class]");

      if (exists($class->brik_properties->{attributes})) {
         for my $attribute (keys %{$class->brik_properties->{attributes}}) {
            next unless $attribute =~ /^[a-z]/; # Brik Attributes always begin with a minuscule
            next if $attribute =~ /^_/;         # Internal stuff

            $attributes->{$attribute} = $class->brik_properties->{attributes}->{$attribute};
         }
      }

      last if $class eq 'Metabrik::Brik';
   }

   return $attributes;
}

sub brik_has_attribute {
   my $self = shift; 
   my ($attribute) = @_;

   if (! defined($attribute)) {
      return $self->log->info($self->brik_help_run('brik_has_attribute'));
   }

   if (exists($self->brik_attributes->{$attribute})) {
      return 1;
   }

   return 0;
}

# brik_preinit() directly runs after new() is run. new() is called on use().
sub brik_preinit {
   my $self = shift;

   return $self;
}

sub brik_init {
   my $self = shift;

   if ($self->inited) {
      return;
   }

   $self->inited(1);

   return $self;
}

sub brik_self {
   my $self = shift;

   return $self;
}

# fini() is run at DESTROY time
sub brik_fini {
   my $self = shift;

   return $self;
}

sub DESTROY {
   my $self = shift;

   return $self->brik_fini;
}

1;

__END__
