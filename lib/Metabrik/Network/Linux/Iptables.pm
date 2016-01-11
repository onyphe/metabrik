#
# $Id$
#
# network::linux::iptables Brik
#
package Metabrik::Network::Linux::Iptables;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable fw firewall filter block filtering nat) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         device => [ qw(device) ],
         table => [ qw(nat|filter|mangle|$name) ],
         chain => [ qw(INPUT|OUTPUT|FORWARD|PREROUTING|POSTROUTING|MASQUERADE|$name) ],
         target => [ qw(ACCEPT|REJECT|DROP|RETURN|REDIRECT|$name) ],
         protocol => [ qw(udp|tcp|all) ],
         source => [ qw(source) ],
         destination => [ qw(destination) ],
         test_only => [ qw(0|1) ],
      },
      attributes_default => {
         table => 'filter',
         chain => 'INPUT',
         target => 'REJECT',
         protocol => 'all',
         source => '0.0.0.0/0',
         destination => '0.0.0.0/0',
         test_only => 0,
      },
      commands => {
         install => [ ], # Inherited
         command => [ qw(command) ],
         show_nat => [ ],
         show_filter => [ ],
         save => [ qw(file table|OPTIONAL) ],
         save_nat => [ qw(file) ],
         save_filter => [ qw(file) ],
         restore => [ qw(file table|OPTIONAL) ],
         restore_nat => [ qw(file) ],
         restore_filter => [ qw(file) ],
         flush => [ qw(table|$table_list chain) ],
         flush_nat => [ qw(chain|OPTIONAL) ],
         flush_nat_prerouting => [ ],
         flush_nat_input => [ ],
         flush_nat_output => [ ],
         flush_nat_postrouting => [ ],
         flush_filter => [ qw(chain|OPTIONAL) ],
         flush_filter_input => [ ],
         flush_filter_forward => [ ],
         flush_filter_output => [ ],
         set_policy => [ qw(table target) ],
         set_policy_input => [ qw(target) ],
         set_policy_output => [ qw(target) ],
         set_policy_forward => [ qw(target) ],
         add => [ qw(table chain target source|OPTIONAL destination|OPTIONAL protocol|OPTIONAL custom|OPTIONAL) ],
         add_nat => [ qw(chain target source|OPTIONAL destination|OPTIONAL protocol|OPTIONAL custom|OPTIONAL) ],
         add_nat_output => [ qw(target source|OPTIONAL destination|OPTIONAL protocol|OPTIONAL custom|OPTIONAL) ],
         add_nat_postrouting => [ qw(target source destination protocol|OPTIONAL custom|OPTIONAL) ],
         add_nat_postrouting_masquerade => [ qw(source destination protocol|OPTIONAL custom|OPTIONAL) ],
         add_filter => [ qw(chain target source destination protocol|OPTIONAL custom|OPTIONAL) ],
         add_filter_output => [ qw(target source destination protocol|OPTIONAL custom|OPTIONAL) ],
         add_filter_output_accept => [ qw(source destination protocol|OPTIONAL custom|OPTIONAL) ],
         add_filter_output_reject => [ qw(source destination protocol|OPTIONAL custom|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
      },
      require_binaries => {
         iptables => [ ],
      },
      need_packages => {
         ubuntu => [ qw(iptables) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device,
      },
   };
}

sub command {
   my $self = shift;
   my ($command) = @_;

   $self->brik_help_run_undef_arg('command', $command) or return;

   my $cmd = "iptables $command";

   $self->log->verbose("command: cmd[$cmd]");

   if ($self->test_only) {
      return 1;
   }

   return $self->sudo_execute($command);
}

sub show_nat {
   my $self = shift;

   my $cmd = 'iptables -S -t nat';

   return $self->sudo_execute($cmd);
}

sub show_filter {
   my $self = shift;

   my $cmd = 'iptables -S -t filter';

   return $self->sudo_execute($cmd);
}

sub save {
   my $self = shift;
   my ($output, $table) = @_;

   $self->brik_help_run_undef_arg('save', $output) or return;
   if (-f $output) {
      return $self->log->error("save: file [$output] already exists");
   }

   my $cmd = 'iptables-save -c';
   if (defined($table)) {
      $cmd = "iptables-save -c -t $table";
   }

   $self->log->verbose("save: cmd[$cmd]");

   if ($self->test_only) {
      return 1;
   }

   my $preve = $self->ignore_error;
   my $prevc = $self->capture_stderr;
   $self->ignore_error(0);
   $self->capture_stderr(0);
   my $r = $self->sudo_capture($cmd);
   if (! defined($r)) {
      $self->ignore_error($preve);
      $self->ignore_error($prevc);
      return;
   }
   $self->ignore_error($preve);
   $self->ignore_error($prevc);

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->write($r, $output) or return;

   return $output;
}

sub save_nat {
   my $self = shift;
   my ($output) = @_;

   $self->brik_help_run_undef_arg('save_nat', $output) or return;

   return $self->save($output, 'nat');
}

sub save_filter {
   my $self = shift;
   my ($output) = @_;

   $self->brik_help_run_undef_arg('save_filter', $output) or return;

   return $self->save($output, 'filter');
}

sub restore {
   my $self = shift;
   my ($input, $table) = @_;

   $self->brik_help_run_undef_arg('restore', $input) or return;
   $self->brik_help_run_file_not_found('restore', $input) or return;

   my $cmd = "cat $input | iptables-restore -c";
   if (defined($table)) {
      $cmd = "\"iptables-restore -c -T $table < $input\"";
   }

   $self->log->verbose("restore: cmd[$cmd]");

   if ($self->test_only) {
      return 1;
   }

   my $preve = $self->ignore_error;
   my $prevc = $self->capture_stderr;
   $self->ignore_error(0);
   $self->capture_stderr(0);
   my $r = $self->sudo_capture($cmd);
   if (! defined($r)) {
      $self->ignore_error($preve);
      $self->ignore_error($prevc);
      return;
   }
   $self->ignore_error($preve);
   $self->ignore_error($prevc);

   return $input;
}

sub restore_nat {
   my $self = shift;
   my ($input) = @_;

   $self->brik_help_run_undef_arg('restore_nat', $input) or return;
   $self->brik_help_run_file_not_found('restore_nat', $input) or return;

   return $self->restore($input, 'nat');
}

sub restore_filter {
   my $self = shift;
   my ($input) = @_;

   $self->brik_help_run_undef_arg('restore_filter', $input) or return;
   $self->brik_help_run_file_not_found('restore_filter', $input) or return;

   return $self->restore($input, 'filter');
}

sub flush {
   my $self = shift;
   my ($table, $chain) = @_;

   if (! defined($table)) {
      $table = [ qw(nat filter) ];
   }
   my $ref = $self->brik_help_run_invalid_arg('flush', $table, 'ARRAY', 'SCALAR')
      or return;

   my $cmd = "-t $table -F";

   if ($ref eq 'ARRAY') {
      for my $this (@$table) {
         $self->flush($this, $chain);
      }
      return 1;
   }
   else {
      if (defined($chain)) {
         $cmd = "-t $table -F $chain";
      }
   }

   return $self->command($cmd);
}

sub flush_nat {
   my $self = shift;
   my ($chain) = @_;

   return $self->flush('nat', $chain);
}

sub flush_nat_prerouting {
   my $self = shift;

   return $self->flush_nat('PREROUTING');
}

sub flush_nat_input {
   my $self = shift;

   return $self->flush_nat('INPUT');
}

sub flush_nat_output {
   my $self = shift;

   return $self->flush_nat('OUTPUT');
}

sub flush_nat_postrouting {
   my $self = shift;

   return $self->flush_nat('POSTROUTING');
}

sub flush_filter {
   my $self = shift;
   my ($chain) = @_;

   return $self->flush('filter', $chain);
}

sub flush_filter_input {
   my $self = shift;

   return $self->flush_filter('INPUT');
}

sub flush_filter_forward {
   my $self = shift;

   return $self->flush_filter('FORWARD');
}

sub flush_filter_output {
   my $self = shift;

   return $self->flush_filter('OUTPUT');
}

sub set_policy {
   my $self = shift;
   my ($table, $target) = @_;

   $self->brik_help_run_undef_arg('set_policy', $table) or return;
   $self->brik_help_run_undef_arg('set_policy', $target) or return;

   my $cmd = "-P $table $target";

   return $self->command($cmd);
}

sub set_policy_input {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('set_policy_input', $target) or return;

   return $self->set_policy('input', $target);
}

sub set_policy_output {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('set_policy_output', $target) or return;

   return $self->set_policy('output', $target);
}

sub set_policy_forward {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('set_policy_forward', $target) or return;

   return $self->set_policy('forward', $target);
}

sub add {
   my $self = shift;
   my ($table, $chain, $target, $source, $destination, $protocol, $custom) = @_;

   $table ||= $self->table;
   $chain ||= $self->chain;
   $target ||= $self->target;
   $protocol ||= $self->protocol;
   $source ||= $self->source;
   $destination ||= $self->destination;
   $self->brik_help_run_undef_arg('add', $table) or return;
   $self->brik_help_run_undef_arg('add', $chain) or return;
   $self->brik_help_run_undef_arg('add', $target) or return;
   $self->brik_help_run_undef_arg('add', $source) or return;
   $self->brik_help_run_undef_arg('add', $destination) or return;

   my $cmd = "-t $table -A $chain -j $target -s $source -d $destination -p $protocol";
   if (length($custom)) {
      $cmd .= " $custom";
   }

   return $self->command($cmd);
}

sub add_nat {
   my $self = shift;
   my ($chain, $target, $source, $destination, $protocol, $custom) = @_;

   $chain ||= $self->chain;
   $target ||= $self->target;
   $protocol ||= $self->protocol;
   $source ||= $self->source;
   $destination ||= $self->destination;
   $self->brik_help_run_undef_arg('add_nat', $chain) or return;
   $self->brik_help_run_undef_arg('add_nat', $target) or return;
   $self->brik_help_run_undef_arg('add_nat', $source) or return;
   $self->brik_help_run_undef_arg('add_nat', $destination) or return;

   return $self->add('nat', $chain, $target, $source, $destination, $protocol, $custom);
}

sub add_nat_output {
   my $self = shift;
   my ($target, $source, $destination, $protocol, $custom) = @_;

   $target ||= $self->target;
   $protocol ||= $self->protocol;
   $source ||= $self->source;
   $destination ||= $self->destination;
   $self->brik_help_run_undef_arg('add_nat_output', $target) or return;
   $self->brik_help_run_undef_arg('add_nat_output', $source) or return;
   $self->brik_help_run_undef_arg('add_nat_output', $destination) or return;

   return $self->add_nat('OUTPUT', $target, $source, $destination, $protocol, $custom);
}

sub add_nat_postrouting {
   my $self = shift;
   my ($target, $source, $destination, $protocol, $custom) = @_;

   $target ||= $self->target;
   $protocol ||= $self->protocol;
   $source ||= $self->source;
   $destination ||= $self->destination;
   $self->brik_help_run_undef_arg('add_nat_postrouting', $target) or return;
   $self->brik_help_run_undef_arg('add_nat_postrouting', $source) or return;
   $self->brik_help_run_undef_arg('add_nat_postrouting', $destination) or return;

   return $self->add_nat('POSTROUTING', $target, $source, $destination, $protocol, $custom);
}

sub add_nat_postrouting_masquerade {
   my $self = shift;
   my ($source, $destination, $protocol, $custom) = @_;

   $source ||= $self->source;
   $destination ||= $self->destination;
   $protocol ||= $self->protocol;
   $self->brik_help_run_undef_arg('add_nat_postrouting_masquerade', $source) or return;
   $self->brik_help_run_undef_arg('add_nat_postrouting_masquerade', $destination) or return;

   return $self->add_nat_postrouting('MASQUERADE', $source, $destination, $protocol, $custom);
}

sub add_filter {
   my $self = shift;
   my ($chain, $target, $source, $destination, $protocol, $custom) = @_;

   $chain ||= $self->chain;
   $target ||= $self->target;
   $protocol ||= $self->protocol;
   $source ||= $self->source;
   $destination ||= $self->destination;
   $self->brik_help_run_undef_arg('add_filter', $chain) or return;
   $self->brik_help_run_undef_arg('add_filter', $target) or return;
   $self->brik_help_run_undef_arg('add_filter', $source) or return;
   $self->brik_help_run_undef_arg('add_filter', $destination) or return;

   return $self->add('filter', $chain, $target, $source, $destination, $protocol, $custom);
}

sub add_filter_output {
   my $self = shift;
   my ($target, $source, $destination, $protocol, $custom) = @_;

   $target ||= $self->target;
   $protocol ||= $self->protocol;
   $source ||= $self->source;
   $destination ||= $self->destination;
   $self->brik_help_run_undef_arg('add_filter_output', $target) or return;
   $self->brik_help_run_undef_arg('add_filter_output', $source) or return;
   $self->brik_help_run_undef_arg('add_filter_output', $destination) or return;
   $self->brik_help_run_undef_arg('add_filter_output', $protocol) or return;

   return $self->add_filter('OUTPUT', $target, $source, $destination, $protocol, $custom);
}

sub add_filter_output_accept {
   my $self = shift;
   my ($source, $destination, $protocol, $custom) = @_;

   $source ||= $self->source;
   $destination ||= $self->destination;
   $protocol ||= $self->protocol;
   $self->brik_help_run_undef_arg('add_filter_output_accept', $source) or return;
   $self->brik_help_run_undef_arg('add_filter_output_accept', $destination) or return;
   $self->brik_help_run_undef_arg('add_filter_output_accept', $protocol) or return;

   return $self->add_filter_output('ACCEPT', $source, $destination, $protocol, $custom);
}

sub add_filter_output_reject {
   my $self = shift;
   my ($source, $destination, $protocol, $custom) = @_;

   $source ||= $self->source;
   $destination ||= $self->destination;
   $protocol ||= $self->protocol;
   $self->brik_help_run_undef_arg('add_filter_output_reject', $source) or return;
   $self->brik_help_run_undef_arg('add_filter_output_reject', $destination) or return;
   $self->brik_help_run_undef_arg('add_filter_output_reject', $protocol) or return;

   return $self->add_filter_output('REJECT', $source, $destination, $protocol, $custom);
}

1;

__END__

=head1 NAME

Metabrik::Network::Linux::Iptables - network::linux::iptables Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
