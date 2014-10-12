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

sub version {
   my $self = shift;

   my $revision = $self->properties->{revision};
   $revision =~ s/^.*?(\d+).*?$/$1/;

   return $Metabrik::VERSION.'.'.$revision;
}

sub properties {
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
         version => [ q() ],
         help_set => [ qw(SCALAR) ],
         help_run => [ qw(SCALAR) ],
         class => [ qw() ],
         classes => [ qw() ],
         name => [ qw() ],
         repository => [ qw() ],
         category => [ qw() ],
         tags => [ qw() ],
         has_tag => [ qw(SCALAR) ],
         commands => [ qw() ],
         has_command => [ qw(SCALAR) ],
         attributes => [ qw() ],
         has_attribute => [ qw(SCALAR) ],
         self => [ qw() ],
      },
      require_modules => { },
      require_used => { },
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
      last if $class eq 'Metabrik::Brik';

      my $attributes = $class->attributes;

      if (exists($attributes->{$attribute})) {
         my $help = sprintf("set %s %-20s ", $name, $attribute);
         $help .= join(' ', @{$attributes->{$attribute}});
         return $help;
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
      last if $class eq 'Metabrik::Brik';

      my $commands = $class->commands;

      if (exists($commands->{commands})) {
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

   if (! $self->can('properties')) {
      $self->log->error("new: Brik [".$self->name."] has no properties");
   }

   # Build Attributes, Class::Gomor style
   my $attributes = $self->properties->{attributes};
   my @as = ( keys %$attributes );
   if (@as > 0) {
      no strict 'refs';

      my $class = $self->class;

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

   # Set default values for main Brik class
   my $this_default = __PACKAGE__->properties->{attributes_default};
   for my $k (keys %$this_default) {
      #next unless defined($self->$k); # Do not overwrite if set on new
      $self->$k($this_default->{$k});
   }

   # Set default values for used Brik
   my $attributes_default = $self->properties->{attributes_default};
   for my $k (keys %$attributes_default) {
      #next unless defined($self->$k); # Do not overwrite if set on new
      $self->$k($attributes_default->{$k});
   }

   my $modules = $self->properties->{require_modules};
   for my $module (keys %$modules) {
      eval("require $module;");
      if ($@) {
         chomp($@);
         return $self->log->error("new: you have to install Module [$module]: $@", $self->class);
      }

      my @imports = @{$modules->{$module}};
      if (@imports > 0) {
         eval('$module->import(@imports);');
         if ($@) {
            chomp($@);
            return $self->log->error("new: unable to import Functions [@imports] ".
               "from Module [$module]: $@", $self->class
            );
         }
      }
   }

   # Not all modules are capable of checking context against used briks
   # For instance, core::context Brik itselves.
   if (defined($self->context) && $self->context->can('used')) {
      my $error = 0;
      my $used = $self->context->used;
      my $require_used = $self->properties->{require_used};
      for my $brik (keys %$require_used) {
         if (! $self->context->is_used($brik)) {
            $self->log->error("new: you must use Brik [$brik] first", $self->class);
            $error++;
         }
      }

      if ($error) {
         return;
      }
   }

   return $self->preinit;
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

sub name {
   my $self = shift;

   my $module = lc($self->class);
   $module =~ s/^metabrik::brik:://;

   return $module;
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
      next if ($class !~ /^Metabrik::Brik/);
      push @classes, $class;
   }

   return \@classes;
}

sub tags {
   my $self = shift;

   my $tags = $self->properties->{tags};

   # We add the used tags if Brik has been used.
   # Not all Briks have a context set (core::context don't)
   if ($self->category eq 'core' || ($self->can('context') && $self->context->is_used($self->name))) {
      push @$tags, 'used';
   }

   return [ sort { $a cmp $b } @$tags ];
}

sub has_tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($tag)) {
      return $self->log->info("run ".$self->name." has_tag <tag>");
   }

   my %h = map { $_ => 1 } @{$self->declare_tags};

   if (exists($h{$tag})) {
      return 1;
   }

   return 0;
}

sub commands {
   my $self = shift;

   my $commands = { %{__PACKAGE__->properties->{commands}} };

   if (exists($self->properties->{commands})) {
      for my $command (keys %{$self->properties->{commands}}) {
         #$self->log->info("command[$command]");

         next unless $command =~ /^[a-z]/; # Brik Commands always begin with a minuscule
         next if $command =~ /^cg[A-Z]/; # Class::Gomor stuff
         next if $command =~ /^_/; # Internal stuff
         next if $command =~ /^(?:a|b|import|init|fini|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff

         $commands->{$command} = $self->properties->{commands}->{$command};
      }
   }

   return $commands;
}

sub has_command {
   my $self = shift;
   my ($command) = @_;

   if (! defined($command)) {
      return $self->log->info($self->help_run('has_command'));
   }

   if (exists($self->commands->{$command})) {
      return 1;
   }

   return 0;
}

sub attributes {
   my $self = shift;

   my $attributes = { %{__PACKAGE__->properties->{attributes}} };

   if (exists($self->properties->{attributes})) {
      for my $attribute (keys %{$self->properties->{attributes}}) {
         next unless $attribute =~ /^[a-z]/; # Brik Attributes always begin with a minuscule
         next if $attribute =~ /^_/;         # Internal stuff

         $attributes->{$attribute} = $self->properties->{attributes}->{$attribute};
      }
   }

   return $attributes;
}

sub has_attribute {
   my $self = shift; 
   my ($attribute) = @_;

   if (! defined($attribute)) {
      return $self->log->info($self->help_run('has_attribute'));
   }

   if (exists($self->attributes->{$attribute})) {
      return 1;
   }

   return 0;
}

# preinit() directly runs after new() is run. new() is called on use().
sub preinit {
   my $self = shift;

   return $self;
}

sub init {
   my $self = shift;

   if ($self->inited) {
      return;
   }

   $self->inited(1);

   return $self;
}

sub self {
   my $self = shift;

   return $self;
}

# fini() is run at DESTROY time
sub fini {
   my $self = shift;

   return $self;
}

sub DESTROY {
   my $self = shift;

   return $self->fini;
}

1;

__END__
