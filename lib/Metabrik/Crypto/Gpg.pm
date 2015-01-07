#
# $Id$
#
# crypto::gpg Brik
#
package Metabrik::Crypto::Gpg;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable pgp gpg gnupg) ],
      attributes => {
         public_keyring => [ qw(file.gpg) ],
         secret_keyring => [ qw(file.gpg) ],
         passphrase => [ qw(passphrase) ],
         type_key => [ qw(RSA|DSA) ],
         type_subkey => [ qw(RSA|ELG-E) ],
         length_key => [ qw(1024|2048|3072|4096) ],
         length_subkey => [ qw(1024|2048|3072|4096) ],
         expire_key => [ qw(count_y|0) ],
         _gnupg => [ qw(INTERNAL) ],
      },
      attributes_default => {
         public_keyring => $ENV{HOME}."/.gnupg/pubring.gpg",
         secret_keyring =>  $ENV{HOME}."/.gnupg/secring.gpg",
         type_key => 'DSA',
         type_subkey => 'ELG-E',
         length_key => 2048,
         length_subkey => 3072,
         expire_key => '5y',
      },
      commands => {
         list_public_keys => [ ],
         list_secret_keys => [ ],
         get_public_keys => [ qw(keys_list) ],
         get_secret_keys => [ qw(keys_list) ],
         import_keys => [ qw(file) ],
         delete_key => [ qw(key_id) ],
         generate_key => [ qw(email description|OPTIONAL comment|OPTIONAL) ],
         encrypt => [ qw($data email_recipient_list) ],
         decrypt => [ qw($data) ],
         export_keys => [ qw(key_id) ],
      },
      require_modules => {
         'IO::Handle' => [ ],
         'GnuPG::Interface' => [ ],
         'GnuPG::Handles' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::String::Random' => [ ],
         'Metabrik::String::Password' => [ ],
      },
      require_binaries => {
         'rngd' => [ ],  # apt-get install rng-tools
      },
   };
}

sub brik_init {
   my $self = shift;

   my $gnupg = GnuPG::Interface->new;
   if (! $gnupg) {
      return $self->log->error("brik_init: GnuPG::Interface failed");
   }
   $gnupg->options->hash_init(armor => 1);

   $self->_gnupg($gnupg);

   return $self->SUPER::brik_init;
}

sub generate_key {
   my $self = shift;
   my ($email, $description, $comment) = @_;

   if (! defined($email)) {
      return $self->log->error($self->brik_help_run('generate_key'));
   }

   my $passphrase = $self->passphrase;
   if (! defined($passphrase)) {
      return $self->log->error($self->brik_help_set('passphrase'));
   }

   $description ||= $email;
   $comment ||= $email;

   my $type_key = $self->type_key;
   my $type_subkey = $self->type_subkey;
   my $length_key = $self->length_key;
   my $length_subkey = $self->length_subkey;
   my $expire_key = $self->expire_key;

   my $filename = Metabrik::String::Random->new_from_brik($self)->filename
      or return $self->log->error("generate_key: string::random failed");

   my $text = Metabrik::File::Text->new_from_brik($self)
      or return $self->log->error("generate_key: file::text failed");
   $text->output($filename);

   # If key is RSA, subkey will be RSA.
   # If key is DSA, subkey will be Elgamal.
   #my $subkey = $type_key;
   #if ($type_key eq 'DSA') {
      #$subkey = 'Elgamal';
   #}

   $text->write([
      '%echo Generating a standard key', "\n",
      "Key-Type: $type_key", "\n",
      "Key-Length: $length_key", "\n",
      "Subkey-Type: $type_subkey", "\n",
      "Subkey-Length: $length_subkey", "\n",
      "Name-Real: $description", "\n",
      "Name-Email: $email", "\n",
      "Expire-Date: $expire_key", "\n",
      "Passphrase: $passphrase", "\n",
      '#%pubring foo.pub', "\n",
      '#%secring foo.sec', "\n",
      '%commit', "\n",
      '%echo done', "\n",
      ''
   ]);

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
   );

   my $pid = $gnupg->wrap_call(
      commands => [ qw(--batch --gen-key) ],
      command_args => [ $filename ],
      handles => $handles,
   );
    
   my @out = <$stdout>;
   close($stdout);
   my @err = <$stderr>;
   close($stderr);
   waitpid($pid, 0);

   unlink($filename);

   for my $this (@err) {
      chomp($this);
      $self->log->verbose("generate_key: $this");
   }

   return \@out;
}

sub delete_key {
   my $self = shift;
   my ($id) = @_;

   if (! defined($id)) {
      return $self->log->error($self->brik_help_run('delete_key'));
   }

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
   );

   my $pid = $gnupg->wrap_call(
      commands => [ qw(--delete-secret-and-public-key) ],
      command_args => [ $id ],
      handles => $handles,
   );

   my @lines = ();
   while (<$stdout>) {
      chomp;
      push @lines, $_;
   }
   close($stdout);
   waitpid($pid, 0);

   return \@lines;
}

sub import_keys {
   my $self = shift;
   my ($file) = @_;

   if (! defined($file)) {
      return $self->log->error($self->brik_help_run('import_keys'));
   }

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
   );

   my $pid = $gnupg->import_keys(handles => $handles);
   if (! $pid) {
      return $self->log->error("import_keys: import_keys failed");
   }

   my $data = Metabrik::File::Text->new_from_brik($self)->read($file)
      or return $self->log->error("import_keys: file::text failed");

   print $stdin $data;
   close($stdin);

   my @lines = ();
   while (<$stdout>) {
      chomp;
      push @lines, $_;
   }
   close($stdout);
   waitpid($pid, 0);

   return \@lines;

}

sub list_public_keys {
   my $self = shift;

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
   );

   my $pid = $gnupg->list_public_keys(handles => $handles);
   if (! $pid) {
      return $self->log->error("list_public_keys: list_public_keys failed");
   }

   my @lines = ();
   while (<$stdout>) {
      chomp;
      push @lines, $_;
   }
   close($stdout);
   waitpid($pid, 0);

   return \@lines;
}

sub get_public_keys {
   my $self = shift;
   my ($keys) = @_;

   if (! defined($keys)) {
      return $self->log->error($self->brik_help_run('get_public_keys'));
   }

   if (ref($keys) ne 'ARRAY') {
      return $self->log->error("get_public_keys: argument 1 must be ARRAYREF");
   }

   my $gnupg = $self->_gnupg;

   my @keys = $gnupg->get_public_keys_with_sigs(@$keys);

   return \@keys;
}

sub list_secret_keys {
   my $self = shift;

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
   );

   my $pid = $gnupg->list_secret_keys(handles => $handles);
   if (! $pid) {
      return $self->log->error("list_secret_keys: list_secret_keys failed");
   }

   my @lines = ();
   while (<$stdout>) {
      chomp;
      push @lines, $_;
   }
   close($stdout);
   waitpid($pid, 0);

   return \@lines;
}

sub get_secret_keys {
   my $self = shift;
   my ($keys) = @_;

   if (! defined($keys)) {
      return $self->log->error($self->brik_help_run('get_secret_keys'));
   }

   if (ref($keys) ne 'ARRAY') {
      return $self->log->error("get_secret_keys: argument 1 must be ARRAYREF");
   }

   my $gnupg = $self->_gnupg;

   # XXX: does not work
   #my $saved = $gnupg->options->copy;

   my @keys = $gnupg->get_secret_keys(@$keys);

   #$gnupg->options($saved);

   return \@keys;
}

sub encrypt {
   my $self = shift;
   my ($data, $recipient_list) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('encrypt'));
   }

   if (! defined($recipient_list)) {
      return $self->log->error($self->brik_help_run('encrypt'));
   }

   if (ref($recipient_list) ne 'ARRAY') {
      return $self->log->error("encrypt: argument 2 must be ARRAYREF");
   }

   my @data = ();
   if (ref($data) eq 'ARRAY') {
      for my $this (@$data) {
         push @data, $this;
      }
   }
   else {
      if (ref($data) eq 'SCALAR') {
         push @data, $$data;
      }
      else {
         push @data, $data;
      }
   }

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
   );

   for my $email (@$recipient_list) {
      $gnupg->options->push_recipients($email);
   }

   my $pid = $gnupg->encrypt(handles => $handles);
   print $stdin @data;
   close($stdin);

   my @lines = ();
   while (<$stdout>) {
      chomp;
      push @lines, $_;
   }
   close($stdout);
   waitpid($pid, 0);

   return \@lines;
}

sub decrypt {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('decrypt'));
   }

   my $string_password = Metabrik::String::Password->new_from_brik($self);

   my $passphrase = $string_password->prompt;
   if (! defined($passphrase)) {
      return $self->log->error("decrypt: invalid passphrase entered");
   }

   my @data = ();
   if (ref($data) eq 'ARRAY') {
      for my $this (@$data) {
         push @data, $this;
      }
   }
   else {
      if (ref($data) eq 'SCALAR') {
         push @data, $$data;
      }
      else {
         push @data, $data;
      }
   }

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $stdpass = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
      passphrase => $stdpass,
   );

   my $pid = $gnupg->decrypt(handles => $handles);

   # Print passphrase
   print $stdpass $passphrase;
   close($stdpass);

   # Then data to decrypt
   print $stdin @data;
   close($stdin);

   my @lines = ();
   while (<$stdout>) {
      chomp;
      push @lines, $_;
   }
   close($stdout);
   waitpid($pid, 0);

   return \@lines;
}

sub export_keys {
   my $self = shift;
   my ($key_id) = @_;

   if (! defined($key_id)) {
      return $self->log->error($self->brik_help_run('export_keys'));
   }

   my $gnupg = $self->_gnupg;

   my $stdin = IO::Handle->new;
   my $stdout = IO::Handle->new;
   my $stderr = IO::Handle->new;
   my $handles = GnuPG::Handles->new(
      stdin => $stdin,
      stdout => $stdout,
      stderr => $stderr,
   );

   my $pid = $gnupg->export_keys(
      handles => $handles,
      command_args => $key_id,
   );
   if (! $pid) {
      return $self->log->error("export_keys: export_keys failed");
   }

   my @lines = ();
   while (<$stdout>) {
      chomp;
      push @lines, $_;
   }
   close($stdout);
   waitpid($pid, 0);

   return \@lines;
}

1;

__END__

=head1 NAME

Metabrik::Crypto::Gpg - crypto::gpg Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
