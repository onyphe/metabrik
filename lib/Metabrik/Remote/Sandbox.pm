#
# $Id$
#
# remote::sandbox Brik
#
package Metabrik::Remote::Sandbox;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         imap_uri => [ qw(uri) ],
         es_nodes => [ qw(nodes) ],
         es_indices => [ qw(indices) ],
         win_host => [ qw(host) ],
         win_user => [ qw(user) ],
         win_password => [ qw(password) ],
         vm_id => [ qw(id) ],
         vm_snapshot_name => [ qw(name) ],
         _client => [ qw(INTERNAL) ],
         _ci => [ qw(INTERNAL) ],
         _em => [ qw(INTERNAL) ],
         _fb => [ qw(INTERNAL) ],
         _sf => [ qw(INTERNAL) ],
         _fr => [ qw(INTERNAL) ],
         _cs => [ qw(INTERNAL) ],
         _ce => [ qw(INTERNAL) ],
         _rs => [ qw(INTERNAL) ],
         _rw => [ qw(INTERNAL) ],
         _rwd => [ qw(INTERNAL) ],
         _sv => [ qw(INTERNAL) ],
         _fs => [ qw(INTERNAL) ],
      },
      attributes_default => {
         es_nodes => [ qw(http://localhost:9200) ],
         es_indices => 'winlogbeat-*',
         vm_snapshot_name => '666_before_malware',
      },
      commands => {
         create_client => [ ],
         create_imap_client => [ qw(imap_uri|OPTIONAL) ],
         reset_imap_client => [ qw(imap_uri|OPTIONAL) ],
         get_next_email_attachment => [ qw(imap_uri|OPTIONAL) ],
         save_elasticsearch_state => [ ],
         restore_elasticsearch_state => [ ],
         restart_sysmon_collector => [ ],
         upload_and_execute => [ qw(file) ],
         diff_ps_state => [ ],
         diff_ps_network_connections => [ ],
      },
      require_modules => {
         'Metabrik::Client::Imap' => [ ],
         'Metabrik::Email::Message' => [ ],
         'Metabrik::File::Base64' => [ ],
         'Metabrik::File::Raw' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::String::Password' => [ ],
         'Metabrik::Client::Smbclient' => [ ],
         'Metabrik::Client::Elasticsearch' => [ ],
         'Metabrik::Remote::Sysmon' => [ ],
         'Metabrik::Remote::Winsvc' => [ ],
         'Metabrik::Remote::Windefend' => [ ],
         'Metabrik::System::Virtualbox' => [ ],
         'Metabrik::Forensic::Sysmon' => [ ],
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
   my $self = shift;

   return {
      attributes_default => {
      },
   };
}

sub brik_preinit {
   my $self = shift;

   # Do your preinit here, return 0 on error.

   return $self->SUPER::brik_preinit;
}

sub brik_init {
   my $self = shift;

   # Do your init here, return 0 on error.

   return $self->SUPER::brik_init;
}

sub create_client {
   my $self = shift;

   if ($self->_client) {
      return 1;
   }

   my $win_user = $self->win_user;
   my $win_host = $self->win_host;
   my $win_password = $self->win_password;
   my $es_nodes = $self->es_nodes;
   my $vm_id = $self->vm_id;
   $self->brik_help_set_undef_arg('win_user', $win_user) or return;
   $self->brik_help_set_undef_arg('win_host', $win_host) or return;
   $self->brik_help_set_undef_arg('vm_id', $vm_id) or return;

   if (! defined($win_password)) {
      my $sp = Metabrik::String::Password->new_from_brik_init($self) or return;
      $win_password = $sp->prompt or return;
   }

   $self->host($win_host);
   $self->user($win_user);
   $self->password($win_password);

   my $cs = Metabrik::Client::Smbclient->new_from_brik_init($self) or return;
   $cs->host($win_host);
   $cs->user($win_user);
   $cs->password($win_password);

   my $ce = Metabrik::Client::Elasticsearch->new_from_brik_init($self) or return;
   $ce->nodes($es_nodes);
   $ce->open or return;

   my $rs = Metabrik::Remote::Sysmon->new_from_brik_init($self) or return;
   $rs->host($win_host);
   $rs->user($win_user);
   $rs->password($win_password);

   my $rw = Metabrik::Remote::Winsvc->new_from_brik_init($self) or return;
   $rw->host($win_host);
   $rw->user($win_user);
   $rw->password($win_password);

   my $rwd = Metabrik::Remote::Windefend->new_from_brik_init($self) or return;
   $rwd->host($win_host);
   $rwd->user($win_user);
   $rwd->password($win_password);

   my $sv = Metabrik::System::Virtualbox->new_from_brik_init($self) or return;
   $sv->type('headless');

   my $fs = Metabrik::Forensic::Sysmon->new_from_brik_init($self) or return;

   $self->_cs($cs);
   $self->_ce($ce);
   $self->_rs($rs);
   $self->_rw($rw);
   $self->_rwd($rwd);
   $self->_sv($sv);
   $self->_fs($fs);

   return $self->_client(1);
}

sub create_imap_client {
   my $self = shift;
   my ($imap_uri) = @_;

   $imap_uri ||= $self->imap_uri;
   $self->brik_help_set_undef_arg('create_imap_client', $imap_uri) or return;

   my $ci = $self->_ci;
   if (! defined($ci)) {
      $ci = Metabrik::Client::Imap->new_from_brik_init($self) or return;
      $ci->open($imap_uri) or return;
      $self->_ci($ci);

      my $em = Metabrik::Email::Message->new_from_brik_init($self) or return;
      $self->_em($em);

      my $fb = Metabrik::File::Base64->new_from_brik_init($self) or return;
      $self->_fb($fb);

      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      $self->_sf($sf);

      my $fr = Metabrik::File::Raw->new_from_brik_init($self) or return;
      $fr->encoding('ascii');
      $self->_fr($fr);
   }

   return $ci;
}

sub reset_imap_client {
   my $self = shift;

   my $ci = $self->_ci;
   if (defined($ci)) {
      $ci->close;
      $self->_ci(undef);
   }

   return 1;
}

sub get_next_email_attachment {
   my $self = shift;
   my ($imap_uri) = @_;

   $imap_uri ||= $self->imap_uri;
   $self->brik_help_set_undef_arg('get_next_email_attachment', $imap_uri) or return;

   my $ci = $self->create_imap_client($imap_uri);
   my $em = $self->_em;
   my $fb = $self->_fb;
   my $sf = $self->_sf;
   my $fr = $self->_fr;

   my $total = $ci->total;
   for (1..$total) {
      my $next = $ci->read_next or return;
      my $message = $em->parse($next) or return;
      my $headers = $message->[0];
      my @files = ();
      for my $part (@$message) {
         if (exists($part->{filename}) && length($part->{filename})) {
            my $from = $headers->{From};
            my $to = $headers->{To};
            my $subject = $headers->{Subject};
            my $filename = $sf->basefile($part->{filename});
            $filename =~ s{\s+}{_}g; # I hate spaces in filenames.
            my $output = $fb->decode_from_string(
               $part->{file_content}, $self->datadir."/$filename"
            );
            push @files, {
               headers => $headers,
               file => $output,
            };
         }
      }
      return \@files if @files > 0;
   }

   return $self->log->error("get_next_email_attachment: no message ".
      "with an attachment has been found");
}

sub save_elasticsearch_state {
   my $self = shift;

   my $ce = $self->_ce;
   my $indices = $self->es_indices;

   return $ce->create_snapshot_for_indices($indices);
}

sub restore_elasticsearch_state {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $ce = $self->_ce;

   my $indices = $self->es_indices;

   $ce->delete_index($indices) or return;

   $ce->restore_snapshot_for_indices($indices);

   # Waiting for restoration to complete.
   while (! $ce->get_snapshot_state) {
      sleep(1);
   }

   return 1;
}

sub restart_sysmon_collector {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $rs = $self->_rs;
   $rs->generate_conf or return;
   $rs->update_conf or return;
   $rs->redeploy or return;

   my $rw = $self->_rw;
   $rs->restart('winlogbeat') or return;

   return 1;
}

sub upload_and_execute {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;
   $self->brik_help_run_undef_arg('upload_and_execute', $file) or return;
   $self->brik_help_run_file_not_found('upload_and_execute', $file) or return;

   my $ce = $self->_ce;
   my $sv = $self->_sv;
   my $cs = $self->_cs;
   my $rwd = $self->_rwd;
   my $fs = $self->_fs;

   $self->log->info("upload_and_execute: restoring Elasticsearch state...");
   $self->restore_elasticsearch_state or return;
   $self->log->info("upload_and_execute: done.");

   # We create a restore point if none exists yet.
   # Or we restore the previous one.
   my $list = $sv->snapshot_list($self->vm_id) or return;
   my $found = 0;
   for my $this (@$list) {
      if ($this->{name} eq $self->vm_snapshot_name) {
         $found = 1;
         last;
      }
   }
   if (! $found) {
      $self->log->info("upload_and_execute: snapshoting VM state...");
      $sv->snapshot_live($self->vm_id, $self->vm_snapshot_name) or return;
      $self->log->info("upload_and_execute: done.");
   }
   else {
      $self->log->info("upload_and_execute: restoring VM state...");
      $sv->stop($self->vm_id);
      $sv->snapshot_restore($self->vm_id, $self->vm_snapshot_name) or return;
      $sv->start($self->vm_id) or return;
      $self->log->info("upload_and_execute: done.");
   }

   $self->log->info("upload_and_execute: disabling Windows Defender...");
   $rwd->disable or return;
   $self->log->info("upload_and_execute: done.");

   $self->log->info("upload_and_execute: uploading file...");
   $cs->upload($file) or return;
   $self->log->info("upload_and_execute: done.");

   $self->log->info("upload_and_execute: saving sysmon state...");
   $fs->save_state or return;
   $self->log->info("upload_and_execute: done.");

   $self->log->info("upload_and_execute: executing malware...");
   $self->execute('"c:\\windows\\temp\\'.$file.'"');
   $self->log->info("upload_and_execute: done.");

   return 1;
}

sub diff_ps_state {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps');
}

sub diff_ps_network_connections {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps_network_connections');
}

sub brik_fini {
   my $self = shift;

   # Do your fini here, return 0 on error.

   return $self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Sandbox - remote::sandbox Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
