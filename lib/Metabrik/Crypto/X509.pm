#
# $Id$
#
# crypto::x509 Brik
#
package Metabrik::Crypto::X509;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable openssl ssl pki certificate) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(directory) ],
         ca_name => [ qw(name) ],
         ca_lc_name => [ qw(name) ],
         ca_key => [ qw(key_file) ],
         ca_cert => [ qw(cert_file) ],
         ca_directory => [ qw(directory) ],
         ca_conf => [ qw(conf_file) ],
         use_passphrase => [ qw(0|1) ],
         key_size => [ qw(bits) ],
      },
      attributes_default => {
         capture_stderr => 1,
         use_passphrase => 0,
         key_size => 2048,
      },
      commands => {
         ca_init => [ qw(name|OPTIONAL directory|OPTIONAL) ],
         set_ca_attributes => [ qw(name|OPTIONAL) ],
         ca_show => [ qw(name|OPTIONAL) ],
         ca_sign_csr => [ qw(csr_file|OPTIONAL name|OPTIONAL) ],
         csr_new => [ qw(base_file use_passphrase|OPTIONAL) ],
         cert_hash => [ qw(cert_file) ],
         cert_verify => [ qw(cert_file name|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
      },
      require_binaries => {
         'openssl', => [ ],
      },
   };
}

sub set_ca_attributes {
   my $self = shift;
   my ($name) = @_;

   $name ||= $self->ca_name;
   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('set_ca_attributes'));
   }

   my $ca_lc_name = lc($name);
   my $ca_directory = $self->datadir.'/'.$ca_lc_name;

   my $ca_conf = $ca_directory.'/'.$ca_lc_name.'.conf';
   my $ca_cert = $ca_directory.'/'.$ca_lc_name.'.pem';
   my $ca_key = $ca_directory.'/'.$ca_lc_name.'.key';
   my $email = 'dummy@example.com';
   my $organization = 'Dummy Org';

   $self->ca_name($name);
   $self->ca_lc_name($ca_lc_name);
   $self->ca_conf($ca_conf);
   $self->ca_directory($ca_directory);
   $self->ca_cert($ca_cert);
   $self->ca_key($ca_key);

   return 1;
}

sub ca_init {
   my $self = shift;
   my ($name, $directory) = @_;

   $name ||= $self->ca_name;
   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('ca_init'));
   }

   $self->set_ca_attributes($name)
      or return $self->log->error("ca_init: set_ca_attributes failed");

   my $ca_directory = $self->ca_directory;
   if (-d $ca_directory) {
      return $self->log->error("ca_init: ca with name [$name] already exists");
   }
   else {
      mkdir($ca_directory)
         or return $self->log->error("ca_init: mkdir failed with error [$!]");
      mkdir($ca_directory.'/certs');

      my $index_txt = Metabrik::File::Text->new_from_brik($self) or return;
      $index_txt->write('', $ca_directory.'/index.txt')
         or return $self->log->error("ca_init: write index.txt failed");

      my $serial = Metabrik::File::Text->new_from_brik($self) or return;
      $serial->write('01', $ca_directory.'/serial')
         or return $self->log->error("ca_init: write serial failed");
   }

   $self->log->verbose("ca_init: using directory [$ca_directory]");

   my $ca_conf = $self->ca_conf;
   my $ca_cert = $self->ca_cert;
   my $ca_key = $self->ca_key;
   my $ca_lc_name = $self->ca_lc_name;
   my $key_size = $self->key_size;

   my $email = 'dummy@example.com';
   my $organization = 'Dummy Org';

   my $content = [
      "[ ca ]",
      "default_ca = $ca_lc_name",
      "",
      "[ $ca_lc_name ]",
      "dir              =  $ca_directory",
      "certificate      =  $ca_cert",
      "database         =  \$dir/index.txt",
      "#certs            =  \$dir/cert-csr",
      "new_certs_dir    =  \$dir/certs",
      "private_key      =  $ca_key",
      "serial           =  \$dir/serial",
      "default_crl_days = 7",
      "default_days     = 3650",
      "#default_md       = md5",
      "default_md       = sha1",
      "policy           = ${ca_lc_name}_policy",
      "x509_extensions  = certificate_extensions",
      "",
      "[ ${ca_lc_name}_policy ]",
      "commonName              = supplied",
      "stateOrProvinceName     = supplied",
      "countryName             = supplied",
      "organizationName        = supplied",
      "organizationalUnitName  = optional",
      "emailAddress            = optional",
      "",
      "[ certificate_extensions ]",
      "basicConstraints = CA:false",
      "",
      "[ req ]",
      "default_bits       = $key_size",
      "default_keyfile    = $ca_key",
      "#default_md         = md5",
      "default_days       = 1800",
      "default_md         = sha1",
      "prompt             = no",
      "distinguished_name = root_ca_distinguished_name",
      "x509_extensions    = root_ca_extensions",
      "",
      "[ root_ca_distinguished_name ]",
      "commonName          = $name",
      "stateOrProvinceName = Paris",
      "countryName         = FR",
      "emailAddress        = $email",
      "organizationName    = $organization",
      "",
      "[ root_ca_extensions ]",
      "basicConstraints = CA:true",
   ];

   my $file_text = Metabrik::File::Text->new_from_brik($self) or return;
   $file_text->overwrite(1);
   $file_text->write($content, $ca_conf)
      or return $self->log->error("ca_init: write failed");

   $self->log->verbose("ca_init: using conf file [$ca_conf] and cert [$ca_cert]");

   my $cmd = "openssl req -x509 -newkey rsa:$key_size ".
             "-days 1800 -out $ca_cert -outform PEM -config $ca_conf";

   return $self->capture($cmd);
}

sub ca_show {
   my $self = shift;
   my ($name) = @_;

   $name ||= $self->ca_name;
   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('ca_show'));
   }

   $self->set_ca_attributes($name) or return;

   my $ca_cert = $self->ca_cert;
   my $cmd = "openssl x509 -in $ca_cert -text -noout";
   return $self->capture($cmd);
}

sub csr_new {
   my $self = shift;
   my ($base_file, $use_passphrase) = @_;

   if (! defined($base_file)) {
      return $self->log->error($self->brik_help_run('csr_new'));
   }

   $use_passphrase ||= $self->use_passphrase;

   my $datadir = $self->datadir;
   my $csr_cert = $datadir.'/'.$base_file.'.pem';
   my $csr_key = $datadir.'/'.$base_file.'.key';
   my $key_size = $self->key_size;

   if (-f $csr_cert) {
      return $self->log->error("csr_new: file [$csr_cert] already exists");
   }

   my $cmd = "openssl req -newkey rsa:$key_size -keyout $csr_key -keyform PEM ".
             "-out $csr_cert -outform PEM";

   if (! $use_passphrase) {
      $cmd .= " -nodes";
   }

   $self->system($cmd);
   if ($?) {
      return $self->log->error("csr_new: system failed");
   }

   return [ $csr_cert, $csr_key ];
}

sub ca_sign_csr {
   my $self = shift;
   my ($csr_cert, $name) = @_;

   if (! defined($csr_cert)) {
      return $self->log->error($self->brik_help_run('ca_sign_csr'));
   }
   if (! -f $csr_cert) {
      return $self->log->error("ca_sign_csr: file [$csr_cert] does not exists");
   }

   $name ||= $self->ca_name;
   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('ca_sign_csr'));
   }

   $self->set_ca_attributes($name) or return;

   my $ca_directory = $self->ca_directory;
   my $ca_conf = $self->ca_conf;

   my ($base_file) = $csr_cert =~ /\/?(.*)\.pem$/;
   if (! length($base_file)) {
      return $self->log->error("ca_sign_csr: cannot parse file name [$csr_cert]");
   }

   my $signed_cert = $ca_directory.'/certs/'.$base_file.'.pem';
   my $cmd = "openssl ca -in $csr_cert -out $signed_cert -config $ca_conf";
   $self->system($cmd);
   if ($?) {
      return $self->log->error("ca_sign_csr: system failed");
   }

   return $signed_cert;
}

sub cert_hash {
   my $self = shift;
   my ($cert_file) = @_;

   if (! defined($cert_file)) {
      return $self->log->error($self->brik_help_run('cert_hash'));
   }

   if (! -f $cert_file) {
      return $self->log->error("cert_hash: file [$cert_file] not found");
   }

   my $cmd = "openssl x509 -noout -hash -in $cert_file";

   return $self->capture($cmd);
}

sub cert_verify {
   my $self = shift;
   my ($cert_file, $name) = @_;

   if (! defined($cert_file)) {
      return $self->log->error($self->brik_help_run('cert_verify'));
   }
   if (! -f $cert_file) {
      return $self->log->error("cert_verify: file [$cert_file] not found");
   }

   $name ||= $self->ca_name;
   if (! defined($name)) {
      return $self->log->error($self->brik_help_run('cert_verify'));
   }

   $self->set_ca_attributes($name) or return;

   my $ca_directory = $self->ca_directory;

   my $cmd = "openssl verify -CApath $ca_directory $cert_file";

   return $self->capture($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Crypto::X509 - crypto::x509 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
