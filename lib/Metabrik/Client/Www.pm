#
# $Id$
#
# client::www Brik
#
package Metabrik::Client::Www;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable browser http client www) ],
      attributes => {
         uri => [ qw(uri) ],
         mechanize => [ qw(OBJECT) ],
      },
      commands => {
         get => [ ],
         content => [ ],
         post => [ qw(SCALAR) ],
         info => [ ],
         forms => [ ],
         links => [ ],
         headers => [ ],
         status => [ ],
         getcertificate => [ ],
         getcertificate2 => [ qw(SCALAR SCALAR) ],
      },
      require_modules => {
         'Data::Dumper' => [ ],
         'IO::Socket::SSL' => [ ],
         'LWP::UserAgent' => [ ],
         'URI' => [ ],
         'WWW::Mechanize' => [ ],
      },
   };
}

sub get {
   my $self = shift;

   my $uri = $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   $self->debug && $self->log->debug("get: uri[$uri]");

   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

   my $mech = WWW::Mechanize->new;
   $mech->agent_alias('Linux Mozilla');
   #$mech->ssl_opts(SSL_ca_path => '/etc/ssl/certs');
   #$mech->ssl_opts(verify_hostname => 0);

   $mech->get($uri);
   $self->log->verbose("get: GET $uri");

   $self->mechanize($mech);

   return $mech;
}

sub content {
   my $self = shift;

   my $mech = $self->mechanize;
   if (! defined($mech)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   return $mech->content;
}

sub post {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('post'));
   }

   my $uri = $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   if ($self->debug) {
      $self->log->debug("post: uri[$uri]");
      $self->log->debug("post: data[$data]");
   }

   #$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

   my $mech = WWW::Mechanize->new;
   $mech->agent_alias('Linux Mozilla');
   #$mech->ssl_opts(verify_hostname => 0);

   $self->mechanize($mech);
   
   return $mech->post($uri, [ $data ]);
}

sub info {
   my $self = shift;

   if (! defined($self->mechanize)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $mech = $self->mechanize;
   my $headers = $mech->response->headers;

   # Taken from apps.json from Wappalyzer
   my @headers = qw(
      IBM-Web2-Location
      X-Drupal-Cache
      X-Powered-By
      X-Drectory-Script
      Set-Cookie
      X-Powered-CMS
      X-KoobooCMS-Version
      X-ATG-Version
      User-Agent
      X-Varnish
      X-Compressed-By
      X-Firefox-Spdy
      X-ServedBy
      MicrosoftSharePointTeamServices
      Set-Cookie
      Generator
      X-CDN
      Server
      X-Tumblr-User
      X-XRDS-Location
      X-Content-Encoded-By
      X-Ghost-Cache-Status
      X-Umbraco-Version
      X-Rack-Cache
      Liferay-Portal
      X-Flow-Powered
      X-Swiftlet-Cache
      X-Lift-Version
      X-Spip-Cache
      X-Wix-Dispatcher-Cache-Hit
      COMMERCE-SERVER-SOFTWARE
      X-AMP-Version
      X-Powered-By-Plesk
      X-Akamai-Transformed
      X-Confluence-Request-Time
      X-Mod-Pagespeed
      Composed-By
      Via
   );

   if ($self->debug) {
      print Data::Dumper::Dumper($headers)."\n";
   }

   my %info = ();
   for my $hdr (@headers) {
      my $this = $headers->header(lc($hdr));
      $info{$hdr} = $this if defined($this);
   }

   my $title = $mech->title;
   if (defined($title)) {
      print "Title: $title\n";
   }

   for my $k (sort { $a cmp $b } keys %info) {
      print "$k: ".$info{$k}."\n";
   }

   return $mech;
}

sub links {
   my $self = shift;

   if (! defined($self->mechanize)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my @links = ();
   for my $l ($self->mechanize->links) {
      push @links, $l->url;
      print $l->url."\n";
   }

   return \@links;
}

sub headers {
   my $self = shift;

   if (! defined($self->mechanize)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $headers = $self->mechanize->response->headers;
   print Data::Dumper::Dumper($headers)."\n";

   return $headers;
}

sub status {
   my $self = shift;

   if (! defined($self->mechanize)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $mech = $self->mechanize;

   print $mech->status."\n";

   return $mech->status;
}

sub forms {
   my $self = shift;

   if (! defined($self->mechanize)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $mech = $self->mechanize;

   if ($self->debug) {
      print Data::Dumper::Dumper($mech->response->headers)."\n";
   }

   my @forms = $mech->forms;
   my $count = 0; 
   for my $form (@forms) {
      my $name = $form->{attr}->{name} || '(undef)';
      print "$count: name: $name\n";

      for my $input (@{$form->{inputs}}) {
         print "   title:    ".$input->{title}."\n"    if exists $input->{title};
         print "   type:     ".$input->{type}."\n"     if exists $input->{type};
         print "   name:     ".$input->{name}."\n"     if exists $input->{name};
         print "   value:    ".$input->{value}."\n"    if exists $input->{value};
         print "   readonly: ".$input->{readonly}."\n" if exists $input->{readonly};
         print "\n";
      }

      $count++;
   }

   return $mech;
}

#
# Note: works only with IO::Socket::SSL, not with Net:SSL (using Crypt::SSLeay)
#
sub getcertificate {
   my $self = shift;

   my $uri = $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   if ($uri !~ /^https:\/\//) {
      return $self->log->error("must use https to get a certificate");
   }

   my $ua = LWP::UserAgent->new(
      ssl_opts => { verify_hostname => 0 }, # will do manual check
   );
   $ua->timeout($self->global->rtimeout);
   $ua->max_redirect(0);
   $ua->env_proxy;

   my $cache = LWP::ConnCache->new;
   $ua->conn_cache($cache);

   my $response = $ua->get($uri);
   # XXX: we ignore response?

   my $cc = $ua->conn_cache->{cc_conns};
   if (! defined($cc)) {
      return $self->log->error("unable to retrieve connection cache");
   }

   my $sock = $cc->[0][0];

   my %info = ();
   # peer_certificate from IO::Socket::SSL/Crypt::SSLeay
   if ($sock->can('peer_certificate')) {
      my $authority = $sock->peer_certificate('authority'); # issuer
      my $owner = $sock->peer_certificate('owner'); # subject
      my $commonName = $sock->peer_certificate('commonName'); # cn
      my $subjectAltNames = $sock->peer_certificate('subjectAltNames');
      my $sslversion = $sock->get_sslversion;
      my $cipher = $sock->get_cipher;
      my $servername = $sock->get_servername; # Only when SNI is used
      #my $verify_hostname = $sock->verify_hostname('hostname', 'http');

      $info{authority} = $authority;
      $info{owner} = $owner;
      $info{commonName} = $commonName;
      $info{subjectAltNames} = $subjectAltNames;
      $info{sslversion} = $sslversion;
      $info{cipher} = $cipher;
      $info{servername} = $servername;
      #$info{verify_hostname} = $verify_hostname;

      print Data::Dumper::Dumper(\%info)."\n";
   }
   else {
      return $self->log->error("socket [$sock] cannot do 'peer_certificate'");
   }

   #$sock->stop_SSL;

   return $sock;
}

use Net::SSLeay qw/XN_FLAG_RFC2253 ASN1_STRFLGS_ESC_MSB/;

# Taken from http://cpansearch.perl.org/src/MIKEM/Net-SSLeay-1.57/examples/x509_cert_details.pl
sub get_cert_details {
  my $x509 = shift;
  my $rv = {};
  my $flag_rfc22536_utf8 = (XN_FLAG_RFC2253) & (~ ASN1_STRFLGS_ESC_MSB);

  die 'ERROR: $x509 is NULL, gonna quit' unless $x509;

  #warn "Info: dumping subject\n";
  my $subj_name = Net::SSLeay::X509_get_subject_name($x509);
  my $subj_count = Net::SSLeay::X509_NAME_entry_count($subj_name);
  $rv->{subject}->{count} = $subj_count;
  $rv->{subject}->{oneline} = Net::SSLeay::X509_NAME_oneline($subj_name);
  $rv->{subject}->{print_rfc2253} = Net::SSLeay::X509_NAME_print_ex($subj_name);
  $rv->{subject}->{print_rfc2253_utf8} = Net::SSLeay::X509_NAME_print_ex($subj_name, $flag_rfc22536_utf8);
  $rv->{subject}->{print_rfc2253_utf8_decoded} = Net::SSLeay::X509_NAME_print_ex($subj_name, $flag_rfc22536_utf8, 1);
  for my $i (0..$subj_count-1) {
    my $entry = Net::SSLeay::X509_NAME_get_entry($subj_name, $i);
    my $asn1_string = Net::SSLeay::X509_NAME_ENTRY_get_data($entry);
    my $asn1_object = Net::SSLeay::X509_NAME_ENTRY_get_object($entry);
    my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object);
    $rv->{subject}->{entries}->[$i] = {
          oid  => Net::SSLeay::OBJ_obj2txt($asn1_object,1),
          data => Net::SSLeay::P_ASN1_STRING_get($asn1_string),
          data_utf8_decoded => Net::SSLeay::P_ASN1_STRING_get($asn1_string, 1),
          nid  => ($nid>0) ? $nid : undef,
          ln   => ($nid>0) ? Net::SSLeay::OBJ_nid2ln($nid) : undef,
          sn   => ($nid>0) ? Net::SSLeay::OBJ_nid2sn($nid) : undef,
    };
  }

  #warn "Info: dumping issuer\n";
  my $issuer_name = Net::SSLeay::X509_get_issuer_name($x509);
  my $issuer_count = Net::SSLeay::X509_NAME_entry_count($issuer_name);
  $rv->{issuer}->{count} = $issuer_count;
  $rv->{issuer}->{oneline} = Net::SSLeay::X509_NAME_oneline($issuer_name);
  $rv->{issuer}->{print_rfc2253} = Net::SSLeay::X509_NAME_print_ex($issuer_name);
  $rv->{issuer}->{print_rfc2253_utf8} = Net::SSLeay::X509_NAME_print_ex($issuer_name, $flag_rfc22536_utf8);
  $rv->{issuer}->{print_rfc2253_utf8_decoded} = Net::SSLeay::X509_NAME_print_ex($issuer_name, $flag_rfc22536_utf8, 1);
  for my $i (0..$issuer_count-1) {
    my $entry = Net::SSLeay::X509_NAME_get_entry($issuer_name, $i);
    my $asn1_string = Net::SSLeay::X509_NAME_ENTRY_get_data($entry);
    my $asn1_object = Net::SSLeay::X509_NAME_ENTRY_get_object($entry);
    my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object);
    $rv->{issuer}->{entries}->[$i] = {
          oid  => Net::SSLeay::OBJ_obj2txt($asn1_object,1),
          data => Net::SSLeay::P_ASN1_STRING_get($asn1_string),
          data_utf8_decoded => Net::SSLeay::P_ASN1_STRING_get($asn1_string, 1),
          nid  => ($nid>0) ? $nid : undef,
          ln   => ($nid>0) ? Net::SSLeay::OBJ_nid2ln($nid) : undef,
          sn   => ($nid>0) ? Net::SSLeay::OBJ_nid2sn($nid) : undef,
    };
  }

  #warn "Info: dumping alternative names\n";
  $rv->{subject}->{altnames} = [ Net::SSLeay::X509_get_subjectAltNames($x509) ];
  #XXX-TODO maybe add a function for dumping issuerAltNames
  #$rv->{issuer}->{altnames} = [ Net::SSLeay::X509_get_issuerAltNames($x509) ];

  #warn "Info: dumping hashes/fingerprints\n";
  $rv->{hash}->{subject} = { dec=>Net::SSLeay::X509_subject_name_hash($x509), hex=>sprintf("%X",Net::SSLeay::X509_subject_name_hash($x509)) };
  $rv->{hash}->{issuer}  = { dec=>Net::SSLeay::X509_issuer_name_hash($x509),  hex=>sprintf("%X",Net::SSLeay::X509_issuer_name_hash($x509)) };
  $rv->{hash}->{issuer_and_serial} = { dec=>Net::SSLeay::X509_issuer_and_serial_hash($x509), hex=>sprintf("%X",Net::SSLeay::X509_issuer_and_serial_hash($x509)) };
  $rv->{fingerprint}->{md5}  = Net::SSLeay::X509_get_fingerprint($x509, "md5");
  $rv->{fingerprint}->{sha1} = Net::SSLeay::X509_get_fingerprint($x509, "sha1");
  my $sha1_digest = Net::SSLeay::EVP_get_digestbyname("sha1");
  $rv->{digest_sha1}->{pubkey} = Net::SSLeay::X509_pubkey_digest($x509, $sha1_digest);
  $rv->{digest_sha1}->{x509} = Net::SSLeay::X509_digest($x509, $sha1_digest);

  #warn "Info: dumping expiration\n";
  $rv->{not_before} = Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notBefore($x509));
  $rv->{not_after}  = Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($x509));

  #warn "Info: dumping serial number\n";
  my $ai = Net::SSLeay::X509_get_serialNumber($x509);
  $rv->{serial} = {
    hex  => Net::SSLeay::P_ASN1_INTEGER_get_hex($ai),
    dec  => Net::SSLeay::P_ASN1_INTEGER_get_dec($ai),
    long => Net::SSLeay::ASN1_INTEGER_get($ai),
  };
  $rv->{version} = Net::SSLeay::X509_get_version($x509);

  #warn "Info: dumping extensions\n";
  my $ext_count = Net::SSLeay::X509_get_ext_count($x509);
  $rv->{extensions}->{count} = $ext_count;
  for my $i (0..$ext_count-1) {
    my $ext = Net::SSLeay::X509_get_ext($x509,$i);
    my $asn1_string = Net::SSLeay::X509_EXTENSION_get_data($ext);
    my $asn1_object = Net::SSLeay::X509_EXTENSION_get_object($ext);
    my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object);
    $rv->{extensions}->{entries}->[$i] = {
        critical => Net::SSLeay::X509_EXTENSION_get_critical($ext),
        oid      => Net::SSLeay::OBJ_obj2txt($asn1_object,1),
        nid      => ($nid>0) ? $nid : undef,
        ln       => ($nid>0) ? Net::SSLeay::OBJ_nid2ln($nid) : undef,
        sn       => ($nid>0) ? Net::SSLeay::OBJ_nid2sn($nid) : undef,
        data     => Net::SSLeay::X509V3_EXT_print($ext),
    };
  }

  #warn "Info: dumping CDP\n";
  $rv->{cdp} = [ Net::SSLeay::P_X509_get_crl_distribution_points($x509) ];
  #warn "Info: dumping extended key usage\n";
  $rv->{extkeyusage} = {
    oid => [ Net::SSLeay::P_X509_get_ext_key_usage($x509,0) ],
    nid => [ Net::SSLeay::P_X509_get_ext_key_usage($x509,1) ],
    sn  => [ Net::SSLeay::P_X509_get_ext_key_usage($x509,2) ],
    ln  => [ Net::SSLeay::P_X509_get_ext_key_usage($x509,3) ],
  };
  #warn "Info: dumping key usage\n";
  $rv->{keyusage} = [ Net::SSLeay::P_X509_get_key_usage($x509) ];
  #warn "Info: dumping netscape cert type\n";
  $rv->{ns_cert_type} = [ Net::SSLeay::P_X509_get_netscape_cert_type($x509) ];

  #warn "Info: dumping other info\n";
  $rv->{certificate_type} = Net::SSLeay::X509_certificate_type($x509);
  $rv->{signature_alg} = Net::SSLeay::OBJ_obj2txt(Net::SSLeay::P_X509_get_signature_alg($x509));
  $rv->{pubkey_alg} = Net::SSLeay::OBJ_obj2txt(Net::SSLeay::P_X509_get_pubkey_alg($x509));
  $rv->{pubkey_size} = Net::SSLeay::EVP_PKEY_size(Net::SSLeay::X509_get_pubkey($x509));
  $rv->{pubkey_bits} = Net::SSLeay::EVP_PKEY_bits(Net::SSLeay::X509_get_pubkey($x509));
  $rv->{pubkey_id} = Net::SSLeay::EVP_PKEY_id(Net::SSLeay::X509_get_pubkey($x509));

  return $rv;
}

# This routine will only check the certificate chain, not the actual contact
# of the certificate. You still have to check for CN validity and expiration date.
sub verify {
   my ($ok, $x509_store_ctx) = @_;

   print "**** Verify called ($ok)\n";

   my $x = Net::SSLeay::X509_STORE_CTX_get_current_cert($x509_store_ctx);
   if ($x) {
      print "Certificate:\n";
      print "  Subject Name: "
	    . Net::SSLeay::X509_NAME_oneline(
	       Net::SSLeay::X509_get_subject_name($x))
            . "\n";
      print "  Issuer Name:  "
            . Net::SSLeay::X509_NAME_oneline(
               Net::SSLeay::X509_get_issuer_name($x))
            . "\n";
   }

   return $ok;
}

sub getcertificate2 {
   my $self = shift;
   my ($host, $port) = @_;

   if (! defined($port)) {
      return $self->log->error($self->brik_help_run('getcertificate2'));
   }

   use Net::SSLeay qw(print_errs set_fd);

   if (defined($ENV{HTTPS_PROXY})) {
      my $proxy = URI->new($ENV{HTTPS_PROXY});
      my $user = '';
      my $pass = '';
      my $userinfo = $proxy->userinfo;
      if (defined($userinfo)) {
         ($user, $pass) = split(':', $userinfo);
      }
      my $host = $proxy->host;
      my $port = $proxy->port;
      Net::SSLeay::set_proxy($host, $port, $user, $pass);
   }

   # Taken from Net::SSLeay source code: sslcat()
   my ($got, $errs) = Net::SSLeay::open_proxy_tcp_connection($host, $port);
   if (! $got) {
      return $self->log->error("Net::SSLeay::open_proxy_tcp_connection: $errs");
   }

   Net::SSLeay::initialize();

   my $ctx = Net::SSLeay::new_x_ctx();
   if ($errs = print_errs('Net::SSLeay::new_x_ctx') || ! $ctx) {
      return $self->log->error($errs);
   }

   Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);
   if ($errs = print_errs('Net::SSLeay::CTX_set_options')) {
      return $self->log->error($errs);
   }

   # Certificate chain verification routines
   Net::SSLeay::CTX_set_default_verify_paths($ctx);
   my $cert_dir = '/etc/ssl/certs';
   Net::SSLeay::CTX_load_verify_locations($ctx, '', $cert_dir)
      or return $self->log->error("CTX load verify loc=`$cert_dir' $!");
   Net::SSLeay::CTX_set_verify($ctx, 0, \&verify);
   #die_if_ssl_error('callback: ctx set verify');

   # XXX: skipped client certs part from sslcat()

   my $ssl = Net::SSLeay::new($ctx);
   if ($errs = print_errs('Net::SSLeay::new')) {
      return $self->log->error($errs);
   }

   set_fd($ssl, fileno(Net::SSLeay::SSLCAT_S));
   if ($errs = print_errs('fileno')) {
      return $self->log->error($errs);
   }

   # Gather cipher list
   my $i = 0;
   my @cipher_list = ();
   my $cont = 1;
   while ($cont) {
      my $cipher = Net::SSLeay::get_cipher_list($ssl, $i);
      if (! $cipher) {
         #print "DEBUG last cipher\n";
         $cont = 0;
         last;
      }
      #print "cipher [$cipher]\n";
      push @cipher_list, $cipher;
      $i++;
   }

   $got = Net::SSLeay::connect($ssl);
   if (! $got) {
      $errs = print_errs('Net::SSLeay::connect');
      return $self->log->error($errs);
   }

   my $cipher = Net::SSLeay::get_cipher($ssl);
   print "Using cipher [$cipher]\n";

   print Net::SSLeay::dump_peer_certificate($ssl);

   my $server_cert = Net::SSLeay::get_peer_certificate($ssl);
   #print "get_peer_certificate: ".Data::Dumper::Dumper($server_cert)."\n";

   my $cert_details = get_cert_details($server_cert);
   #print Data::Dumper::Dumper($cert_details)."\n";

   my @rv = Net::SSLeay::get_peer_cert_chain($ssl);
   #print "get_peer_cert_chain: ".Data::Dumper::Dumper(\@rv)."\n";

   my $rv = Net::SSLeay::get_verify_result($ssl);
   print "get_verify_result: ".Data::Dumper::Dumper($rv)."\n";

   #print 'Subject Name: '.Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($server_cert)).
   #"\n".'Issuer  Name: '.Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($server_cert))."\n";

   my $subj_name = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($server_cert));
   print "$subj_name\n";

   #my $pem = Net::SSLeay::PEM_get_string_X509_CRL($server_cert);



   #
   # X509 certificate details
   #

#   # X509 version
#   my $version = Net::SSLeay::X509_get_version($server_cert);
#   print "version: $version\n";
#
#   # Number of extension used
#   my $ext_count = Net::SSLeay::X509_get_ext_count($server_cert);
#   print "ext_count: $ext_count\n";
#
#   # Extensions
#   # X509_get_ext
#   for my $index (0..$ext_count-1) {
#      my $ext = Net::SSLeay::X509_get_ext($server_cert, $index);
#      #my $data = Net::SSLeay::X509_EXTENSION_get_data($ext);
#      #my $string = Net::SSLeay::P_ASN1_STRING_get($data);
#      #print Data::Dumper::Dumper($string)."\n";
#
#      print "EXT: ".Net::SSLeay::X509V3_EXT_print($ext)."\n";
#   }
#
#   # Fingerprint
#   my $fingerprint = Net::SSLeay::X509_get_fingerprint($server_cert, "md5");
#   print "MD5 fingerprint: $fingerprint\n";
#   $fingerprint = Net::SSLeay::X509_get_fingerprint($server_cert, "sha1");
#   print "SHA-1 fingerprint: $fingerprint\n";
#   $fingerprint = Net::SSLeay::X509_get_fingerprint($server_cert, "sha256");
#   print "SHA-256 fingerprint: $fingerprint\n";
#   $fingerprint = Net::SSLeay::X509_get_fingerprint($server_cert, "ripemd160");
#   print "RIPEMD160 fingerprint: $fingerprint\n";
#
#   # Issuer name
#   my $issuer = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($server_cert));
#   print "issuer: $issuer\n";
#
#   # Not after
#   my $time = Net::SSLeay::X509_get_notAfter($server_cert);
#   my $not_after = Net::SSLeay::P_ASN1_TIME_get_isotime($time);
#   print "not after: $not_after\n";
#
#   # Not before
#   $time = Net::SSLeay::X509_get_notBefore($server_cert);
#   my $not_before = Net::SSLeay::P_ASN1_TIME_get_isotime($time);
#   print "not before: $not_before\n";
#
#   # What kind of encryption is using the public key
#   my $pubkey = Net::SSLeay::X509_get_pubkey($server_cert);
#   my $type = Net::SSLeay::EVP_PKEY_id($pubkey);
#   my $encryption_type = Net::SSLeay::OBJ_nid2sn($type);
#   print "pubkey: $encryption_type\n";
#
#   # 
#   @rv = Net::SSLeay::X509_get_subjectAltNames($server_cert);
#   print Data::Dumper::Dumper(\@rv)."\n";
#
#   # Serial number
#   my $serial_number = Net::SSLeay::X509_get_serialNumber($server_cert);
#   print "serial_number: $serial_number\n";

   return $server_cert;
}

1;

__END__

=head1 NAME

Metabrik::Client::Www - client::www Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
