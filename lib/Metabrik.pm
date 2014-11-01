#
# $Id$
#
package Metabrik;
use strict;
use warnings;

our $VERSION = '1.00_07';

use base qw(Class::Gomor::Hash);

our @AS = qw(
   debug
   init_done
   context
   global
   log
   shell
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub brik_version {
   my $self = shift;

   my $revision = $self->brik_properties->{revision};
   $revision =~ s/^.*?(\d+).*?$/$1/;

   return $VERSION.'.'.$revision;
}

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw() ],
      attributes => {
         debug => [ qw(0|1) ],
         init_done => [ qw(0|1) ],
         context => [ qw(core::context) ],
         global => [ qw(core::global) ],
         log => [ qw(core::log) ],
         shell => [ qw(core::shell) ],
      },
      attributes_default => {
         debug => 0,
         init_done => 0,
      },
      commands => {
         brik_version => [ ],
         brik_help_set => [ qw(Attribute) ],
         brik_help_run => [ qw(Command) ],
         brik_class => [ ],
         brik_classes => [ ],
         brik_name => [ ],
         brik_repository => [ ],
         brik_category => [ ],
         brik_tags => [ ],
         brik_has_tag => [ qw(Tag) ],
         brik_commands => [ ],
         brik_has_command => [ qw(Command) ],
         brik_attributes => [ ],
         brik_has_attribute => [ qw(Attribute) ],
         brik_self => [ ],
         brik_create_attributes => [ ],
         brik_set_default_attributes => [ ],
         brik_check_require_modules => [ ],
         brik_check_require_used => [ ],
         brik_check_require_binaries => [ ],
         brik_check_properties => [ ],
      },
      require_modules => { },
      require_used => { },
      require_binaries => { },
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
      last if $class eq 'Metabrik';

      my $attributes = $class->brik_attributes;

      if (exists($attributes->{$attribute})) {
         my $help = sprintf("set %s %s ", $name, $attribute);
         for (@{$attributes->{$attribute}}) {
            $help .= "<$_> ";
         }
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
      last if $class eq 'Metabrik';

      my $commands = $class->brik_commands;

      if (exists($commands->{$command})) {
         my $help = sprintf("run %s %s ", $name, $command);
         for (@{$commands->{$command}}) {
            $help .= "<$_> ";
         }
         return $help;
      }
   }

   return;
}

sub brik_check_properties {
   my $self = shift;

   my $name = $self->brik_name;
   if (! $self->can('brik_properties')) {
      return $self->log->error("brik_check_properties: Brik [$name] ".
         "has no brik_properties");
   }

   my $properties = $self->brik_properties;
   my $use_properties = $self->brik_use_properties;

   my $error = 0;

   # Check all mandatory keys are present
   my @mandatory_keys = qw(
      tags
   );
   for my $key (@mandatory_keys) {
      if (! exists($properties->{$key})) {
         print("[-] brik_check_properties: Brik [$name]: brik_properties lacks mandatory key [$key]\n");
         $error++;
      }
   }

   # Check all keys are valid
   my %valid_keys = (
      revision => 1,
      tags => 1,
      attributes => 1,
      attributes_default => 1,
      commands => 1,
      require_modules => 1,
      require_used => 1,
      require_binaries => 1,
   );
   for my $key (keys %$properties) {
      if (! exists($valid_keys{$key})) {
         print("[-] brik_check_properties: brik_properties has invalid key [$key]\n");
         $error++;
      }
      elsif ($key eq 'tags' && ref($properties->{$key}) ne 'ARRAY') {
         print("[-] brik_check_properties: brik_properties with key [$key] is not an ARRAYREF\n");
         $error++;
      }
      elsif ($key ne 'revision' && $key ne 'tags' && ref($properties->{$key}) ne 'HASH') {
         print("[-] brik_check_properties: brik_properties with key [$key] is not a HASHREF\n");
         $error++;
      }
   }
   for my $key (keys %$use_properties) {
      if (! exists($valid_keys{$key})) {
         print("[-] brik_check_properties: brik_use_properties has invalid key [$key]\n");
         $error++;
      }
      elsif ($key eq 'tags' && ref($use_properties->{$key}) ne 'ARRAY') {
         print("[-] brik_check_properties: brik_use_properties with key [$key] is not an ARRAYREF\n");
         $error++;
      }
      elsif ($key ne 'revision' && $key ne 'tags' && ref($use_properties->{$key}) ne 'HASH') {
         print("[-] brik_check_properties: brik_use_properties with key [$key] is not a HASHREF\n");
         $error++;
      }
   }

   # Check HASHREFs contains pointers to ARRAYREFs
   for my $key (keys %$properties) {
      next if ($key eq 'revision' || $key eq 'tags' || $key eq 'attributes_default');

      for my $subkey (keys %{$properties->{$key}}) {
         if (ref($properties->{$key}->{$subkey}) ne 'ARRAY') {
            print("[-] brik_check_properties: brik_properties with key [$key] and subkey [$subkey] is not an ARRAYREF\n");
            $error++;
         }
      }
   }
   for my $key (keys %$use_properties) {
      next if ($key eq 'revision' || $key eq 'tags' || $key eq 'attributes_default');

      for my $subkey (keys %{$use_properties->{$key}}) {
         if (ref($use_properties->{$key}->{$subkey}) ne 'ARRAY') {
            print("[-] brik_check_properties: brik_use_properties with key [$key] and subkey [$subkey] is not an ARRAYREF\n");
            $error++;
         }
      }
   }

   if ($error) {
      print("[-] brik_check_properties: Brik [$name] has invalid properties ($error error(s) found)\n");
      return 0;
   }

   return 1;
}

sub brik_check_use_properties {
   my $self = shift;

   my $name = $self->brik_name;
   if (! $self->can('brik_use_properties')) {
      return 1;
   }

   my $use_properties = $self->brik_use_properties;

   my $error = 0;

   # Check all mandatory keys are present
   my @mandatory_keys = qw(
   );
   for my $key (@mandatory_keys) {
      if (! exists($use_properties->{$key})) {
         print("[-] brik_check_use_properties: Brik [$name]: brik_use_properties lacks mandatory key [$key]\n");
         $error++;
      }
   }

   # Check all keys are valid
   my %valid_keys = (
      revision => 1,
      tags => 1,
      attributes => 1,
      attributes_default => 1,
      commands => 1,
      require_modules => 1,
      require_used => 1,
      require_binaries => 1,
   );
   for my $key (keys %$use_properties) {
      if (! exists($valid_keys{$key})) {
         print("[-] brik_check_use_properties: brik_use_properties has invalid key [$key]\n");
         $error++;
      }
      elsif ($key eq 'tags' && ref($use_properties->{$key}) ne 'ARRAY') {
         print("[-] brik_check_use_properties: brik_use_properties with key [$key] is not an ARRAYREF\n");
         $error++;
      }
      elsif ($key ne 'revision' && $key ne 'tags' && ref($use_properties->{$key}) ne 'HASH') {
         print("[-] brik_check_use_properties: brik_use_properties with key [$key] is not a HASHREF\n");
         $error++;
      }
   }

   # Check HASHREFs contains pointers to ARRAYREFs
   for my $key (keys %$use_properties) {
      next if ($key eq 'revision' || $key eq 'tags' || $key eq 'attributes_default');

      for my $subkey (keys %{$use_properties->{$key}}) {
         if (ref($use_properties->{$key}->{$subkey}) ne 'ARRAY') {
            print("[-] brik_check_use_properties: brik_use_properties with key [$key] and subkey [$subkey] is not an ARRAYREF\n");
            $error++;
         }
      }
   }

   if ($error) {
      print("[-] brik_check_use_properties: Brik [$name] has invalid properties ($error error(s) found)\n");
      return 0;
   }

   return 1;
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $r = $self->brik_check_properties;
   return unless $r;

   $r = $self->brik_check_use_properties;
   return unless $r;

   $r = $self->brik_create_attributes;
   return unless $r;

   $r = $self->brik_set_default_attributes;
   return unless $r;

   $r = $self->brik_check_require_modules;
   return unless $r;

   $r = $self->brik_check_require_used;
   return unless $r;

   $r = $self->brik_check_require_binaries;
   return unless $r;

   return $self->brik_preinit;
}

sub brik_create_attributes {
   my $self = shift;

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

   return 1;
}

sub brik_set_default_attributes {
   my $self = shift;

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

      last if $class eq 'Metabrik';
   }

   # Then we look at standard default attributes
   if ($self->can('brik_use_properties') && exists($self->brik_use_properties->{attributes_default})) {
      for my $attribute (keys %{$self->brik_use_properties->{attributes_default}}) {
         #next unless defined($self->$attribute); # Do not overwrite if set on new
         $self->$attribute($self->brik_use_properties->{attributes_default}->{$attribute});
      }
   }

   return 1;
}

sub brik_check_require_modules {
   my $self = shift;

   # Module check
   my $modules = $self->brik_properties->{require_modules};
   for my $module (keys %$modules) {
      eval("require $module;");
      if ($@) {
         chomp($@);
         if (defined($self->{log})) {
            return $self->log->error("brik_check_require_modules: you have to ".
               "install Module [$module]: $@", $self->brik_class
            );
         }
         else {
            print("[-] brik_check_require_modules: you have to ".
               "install Module [$module]: $@", $self->brik_class
            );
            return;
         }
      }

      my @imports = @{$modules->{$module}};
      if (@imports > 0) {
         eval('$module->import(@imports);');
         if ($@) {
            chomp($@);
            return $self->log->error("brik_check_require_modules: ".
               "unable to import Functions [@imports] ".
               "from Module [$module]: $@", $self->brik_class
            );
         }
      }
   }

   return 1;
}

sub brik_check_require_used {
   my $self = shift;

   my $context = $self->context;

   # Not all modules are capable of checking context against used briks
   # For instance, core::context Brik itselves.
   if (defined($context) && $context->can('used')) {
      my $error = 0;
      my $used = $context->used;
      my $require_used = $self->brik_properties->{require_used};
      for my $brik (keys %$require_used) {
         if (! $context->is_used($brik)) {
            if ($self->global->auto_use) {
               my $r = $context->use($brik);
               if (! $r) {
                  $self->log->warning("brik_check_require_used: ".
                     "use: Brik [$brik] failed");
                  $error++;
                  next;
               }
               else {
                  $self->log->verbose("brik_check_require_used: ".
                     "use: Brik [$brik] success");
               }
            }
            else {
               $self->log->error("brik_check_require_used: you must use ".
                  "Brik [$brik] first", $self->brik_class
               );
               $error++;
            }
         }
      }

      if ($error) {
         return;
      }
   }

   return 1;
}

sub brik_check_require_binaries {
   my $self = shift;

   my $binaries = $self->brik_properties->{require_binaries};
   my %binaries_found = ();
   for my $binary (keys %$binaries) {
      $binaries_found{$binary} = 0;
      my @path = split(':', $ENV{PATH});
      for my $path (@path) {
         if (-f "$path/$binary") {
            $binaries_found{$binary} = 1;
            last;
         }
      }
   }

   my $error = 0;
   for my $binary (keys %binaries_found) {
      if (! $binaries_found{$binary}) {
         $self->log->error("brik_check_require_modules: binary [$binary] not found in \$PATH");
         $error++;
      }
   }

   return $error ? 0 : 1;
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

   # Error, repository not found
   return $self->log->fatal("brik_repository: no Repository found for Brik [$name] (invalid format?)");
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
   return $self->log->fatal("brik_category: no Category found for Brik [$name] (invalid format?)");
}

sub brik_name {
   my $self = shift;

   my $module = lc($self->brik_class);
   $module =~ s/^metabrik:://;

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
      next if ($class !~ /^Metabrik/);
      push @classes, $class;
   }

   return \@classes;
}

sub brik_tags {
   my $self = shift;

   my $tags = $self->brik_properties->{tags};

   return [ sort { $a cmp $b } @$tags ];
}

sub brik_has_tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($tag)) {
      return $self->log->info($self->brik_help_run('brik_has_tag'));
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
      next unless $class->can('brik_properties');

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

      last if $class eq 'Metabrik';
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
      next unless $class->can('brik_properties');

      #$self->log->info("brik_attributes: class[$class]");

      if (exists($class->brik_properties->{attributes})) {
         for my $attribute (keys %{$class->brik_properties->{attributes}}) {
            next unless $attribute =~ /^[a-z]/; # Brik Attributes always begin with a minuscule
            next if $attribute =~ /^_/;         # Internal stuff

            $attributes->{$attribute} = $class->brik_properties->{attributes}->{$attribute};
         }
      }

      last if $class eq 'Metabrik';
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

   if ($self->init_done) {
      return;
   }

   $self->init_done(1);

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

=head1 NAME

Metabrik - formerly PerL Awesome SHell, Yeeeehaaaaaa!

=head1 SYNOPSIS

   use base qw(Metabrik);

=head1 DESCRIPTION

Base class for Metabrik Briks.

=head2 ATTRIBUTES

=head2 COMMANDS

XXX.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
