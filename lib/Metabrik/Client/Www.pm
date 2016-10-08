#
# $Id$
#
# client::www Brik
#
package Metabrik::Client::Www;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable browser http javascript screenshot) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         ignore_content => [ qw(0|1) ],
         user_agent => [ qw(user_agent) ],
         ssl_verify => [ qw(0|1) ],
         datadir => [ qw(datadir) ],
         timeout => [ qw(0|1) ],
         rtimeout => [ qw(timeout) ],
         add_headers => [ qw(http_headers_hash) ],
         do_javascript => [ qw(0|1) ],
         _client => [ qw(object|INTERNAL) ],
         _last => [ qw(object|INTERNAL) ],
      },
      attributes_default => {
         ssl_verify => 0,
         ignore_content => 0,
         timeout => 0,
         rtimeout => 10,
         add_headers => {},
         do_javascript => 0,
      },
      commands => {
         install => [ ], # Inherited
         create_user_agent => [ ],
         reset_user_agent => [ ],
         get => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         post => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         patch => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         put => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         head => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         delete => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         options => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         code => [ ],
         content => [ ],
         save_content => [ qw(output) ],
         headers => [ ],
         forms => [ ],
         links => [ ],
         trace_redirect => [ qw(uri|OPTIONAL) ],
         screenshot => [ qw(uri output) ],
         eval_javascript => [ qw(js) ],
         info => [ qw(uri|OPTIONAL) ],
         mirror => [ qw(url|$url_list output|OPTIONAL datadir|OPTIONAL) ],
         parse => [ qw(html) ],
         get_last => [ ],
      },
      require_modules => {
         'Progress::Any::Output' => [ ],
         'Progress::Any::Output::TermProgressBarColor' => [ ],
         'Net::SSL' => [ ],
         'Data::Dumper' => [ ],
         'HTML::TreeBuilder' => [ ],
         'LWP::UserAgent' => [ ],
         'LWP::UserAgent::ProgressAny' => [ ],
         'HTTP::Request' => [ ],
         'WWW::Mechanize' => [ ],
         'Metabrik::File::Write' => [ ],
         'Metabrik::Client::Ssl' => [ ],
         'Metabrik::System::File' => [ ],
      },
      optional_modules => {
         'WWW::Mechanize::PhantomJS' => [ ],
      },
      optional_binaries => {
         phantomjs => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libssl-dev phantomjs) ],
      },
   };
}

sub create_user_agent {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $uri ||= $self->uri;
   if ($self->ssl_verify) {
      if (! defined($uri)) {
         return $self->log->error("create_user_agent: you have to give URI argument to check SSL");
      }

      # We have to use a different method to check certificate because all 
      # IO::Socket::SSL, Net::SSL, Net::SSLeay, Net::HTTPS, AnyEvent::TLS just sucks.
      # So we have to perform a first TCP connexion to verify cert, then a second 
      # One to actually negatiate an unverified session.
      my $cs = Metabrik::Client::Ssl->new_from_brik_init($self) or return;
      my $verified = $cs->verify_server($uri);
      if (! defined($verified)) {
         return;
      }
      if ($verified == 0) {
         return $self->log->error("create_user_agent: server [$uri] not verified");
      }
   }

   $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'Net::SSL';

   my $mechanize = 'WWW::Mechanize';
   if ($self->do_javascript) {
      if ($self->brik_has_module('WWW::Mechanize::PhantomJS')
      &&  $self->brik_has_binary('phantomjs')) {
         $mechanize = 'WWW::Mechanize::PhantomJS';
      }
      else {
         return $self->log->error("create_user_agent: module [WWW::Mechanize::PhantomJS] not found, cannot do_javascript");
      }
   }

   my $mech = $mechanize->new(
      autocheck => 0,  # Do not throw on error by checking HTTP code. Let us do it.
      timeout => $self->rtimeout,
      ssl_opts => {
         verify_hostname => 0,
      },
   );
   if (! defined($mech)) {
      return $self->log->error("create_user_agent: unable to create WWW::Mechanize object");
   }

   if ($self->user_agent) {
      $mech->agent($self->user_agent);
   }
   else {
      # Some WWW::Mechanize::* modules can't do that
      if ($mech->can('agent_alias')) {
         $mech->agent_alias('Linux Mozilla');
      }
   }

   $username ||= $self->username;
   $password ||= $self->password;
   if (defined($username) && defined($password)) {
      $self->log->verbose("create_user_agent: using Basic authentication");
      $mech->cookie_jar({});
      $mech->credentials($username, $password);
   }

   return $mech;
}

sub reset_user_agent {
   my $self = shift;

   $self->_client(undef);

   return 1;
}

sub _method {
   my $self = shift;
   my ($uri, $username, $password, $method, $data) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg($method, $uri) or return;

   $self->timeout(0);

   $username ||= $self->username;
   $password ||= $self->password;
   my $client = $self->_client;
   if (! defined($self->_client)) {
      $client = $self->create_user_agent($uri, $username, $password) or return;
      $self->_client($client);
   }

   my $add_headers = $self->add_headers;

   $self->log->verbose("$method: $uri");

   my $response;
   eval {
      if ($method eq 'post' || $method eq 'put') {
         $response = $client->$method($uri, Content => $data);
      }
      elsif ($method eq 'options' || $method eq 'patch') {
         my $req = HTTP::Request->new($method, $uri, $add_headers);
         $response = $client->request($req);
      }
      else {
         $response = $client->$method($uri);
      }
   };
   if ($@) {
      chomp($@);
      if ($@ =~ /read timeout/i) {
         $self->timeout(1);
      }
      return $self->log->error("$method: unable to $method uri [$uri]: $@");
   }

   $self->_last($response);

   my %response = ();
   $response{code} = $response->code;
   if (! $self->ignore_content) {
      if ($self->do_javascript) {
         # decoded_content method is available in WWW::Mechanize::PhantomJS
         # but is available in HTTP::Request response otherwise.
         $response{content} = $client->decoded_content;
      }
      else {
         $response{content} = $response->decoded_content;
      }
   }

   my $headers = $response->headers;
   $response{headers} = { map { $_ => $headers->{$_} } keys %$headers };
   delete $response{headers}->{'::std_case'};

   return \%response;
}

sub get {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'get');
}

sub post {
   my $self = shift;
   my ($href, $uri, $username, $password) = @_;

   $self->brik_help_run_undef_arg('post', $href) or return;

   return $self->_method($uri, $username, $password, 'post', $href);
}

sub put {
   my $self = shift;
   my ($href, $uri, $username, $password) = @_;

   $self->brik_help_run_undef_arg('put', $href) or return;

   return $self->_method($uri, $username, $password, 'put', $href);
}

sub patch {
   my $self = shift;
   my ($href, $uri, $username, $password) = @_;

   $self->brik_help_run_undef_arg('patch', $href) or return;

   return $self->_method($uri, $username, $password, 'patch', $href);
}

sub delete {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'delete');
}

sub options {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'options');
}

sub head {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'head');
}

sub code {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("code: you have to execute a request first");
   }

   return $last->code;
}

sub content {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("content: you have to execute a request first");
   }

   return $last->decoded_content;
}

sub save_content {
   my $self = shift;
   my ($output) = @_;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("save_content: you have to execute a request first");
   }

   eval {
      $self->_client->save_content($output);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("save_content: unable to save content: $@");
   }

   return 1;
}

sub headers {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("headers: you have to execute a request first");
   }

   return $last->headers;
}

sub links {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("links: you have to execute a request first");
   }

   my @links = ();
   for my $l ($self->_client->links) {
      push @links, $l->url;
      $self->log->verbose("links: found link [".$l->url."]");
   }

   return \@links;
}

sub forms {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("forms: you have to execute a request first");
   }

   my $client = $self->_client;

   if ($self->debug) {
      print Data::Dumper::Dumper($last->headers)."\n";
   }

   my @result = ();
   my @forms = $client->forms;
   for my $form (@forms) {
      my $name = $form->{attr}{name} || 'undef';
      my $action = $form->{action};
      my $method = $form->{method} || 'undef';

      my $h = {
         action => $action,
         method => $method,
      };

      for my $input (@{$form->{inputs}}) {
         my $type = $input->{type} || '';
         my $name = $input->{name} || '';
         my $value = $input->{value} || '';
         if ($type eq 'text') {
            push @{$h->{input}}, $name;
         }
      }

      push @result, $h;
   }

   return \@result;
}

sub trace_redirect {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('trace_redirect', $uri) or return;

   my %args = ();
   if (! $self->ssl_verify) {
      $args{ssl_opts} = { SSL_verify_mode => 'SSL_VERIFY_NONE'};
   }

   my $lwp = LWP::UserAgent->new(%args);
   $lwp->timeout($self->rtimeout);
   $lwp->agent('Mozilla/5.0');
   $lwp->max_redirect(0);
   $lwp->env_proxy;

   $username ||= $self->username;
   $password ||= $self->password;
   if (defined($username) && defined($password)) {
      $lwp->credentials($username, $password);
   }

   my @results = ();

   my $location = $uri;
   # Max 20 redirects
   for (1..20) {
      $self->log->verbose("trace_redirect: $location");

      my $response;
      eval {
         $response = $lwp->get($location);
      };
      if ($@) {
         chomp($@);
         return $self->log->error("trace_redirect: unable to get uri [$uri]: $@");
      }

      my $this = {
         uri => $location,
         code => $response->code,
      };
      push @results, $this;

      if ($this->{code} != 302 && $this->{code} != 301) {
         last;
      }

      $location = $this->{location} = $response->headers->{location};
   }

   return \@results;
}

sub screenshot {
   my $self = shift;
   my ($uri, $output) = @_;

   $self->brik_help_run_undef_arg('screenshot', $uri) or return;
   $self->brik_help_run_undef_arg('screenshot', $output) or return;

   if ($self->brik_has_module('WWW::Mechanize::PhantomJS')
   &&  $self->brik_has_binary('phantomjs')) {
      my $mech = WWW::Mechanize::PhantomJS->new
         or return $self->log->error("screenshot: PhantomJS failed");

      my $get = $mech->get($uri)
         or return $self->log->error("screenshot: get uri [$uri] failed");

      my $data = $mech->content_as_png
         or return $self->log->error("screenshot: content_as_png failed");

      my $write = Metabrik::File::Write->new_from_brik_init($self) or return;
      $write->encoding('ascii');
      $write->overwrite(1);
      $write->append(0);

      $write->open($output) or return $self->log->error("screenshot: open failed");
      $write->write($data) or return $self->log->error("screenshot: write failed");
      $write->close;

      return $output;
   }

   return $self->log->error("screenshot: optional module [WWW::Mechanize::PhantomJS] and optional binary [phantomjs] are not available");
}

sub eval_javascript {
   my $self = shift;
   my ($js) = @_;

   $self->brik_help_run_undef_arg('eval_javascript', $js) or return;

   # Perl module Wight may also be an option.

   if ($self->brik_has_module('WWW::Mechanize::PhantomJS')
   &&  $self->brik_has_binary('phantomjs')) {
      my $mech = WWW::Mechanize::PhantomJS->new(launch_arg => ['ghostdriver/src/main.js'])
         or return $self->log->error("eval_javascript: PhantomJS failed");

      return $mech->eval_in_page($js);
   }

   return $self->log->error("eval_javascript: optional module [WWW::Mechanize::PhantomJS] ".
      "and optional binary [phantomjs] are not available");
}

sub info {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('info', $uri) or return;

   my $r = $self->get($uri) or return;
   my $headers = $r->{headers};

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

   my $title = $r->{title};
   if (defined($title)) {
      print "Title: $title\n";
   }

   for my $k (sort { $a cmp $b } keys %info) {
      print "$k: ".$info{$k}."\n";
   }

   return 1;
}

sub mirror {
   my $self = shift;
   my ($url, $output, $datadir) = @_;

   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('mirror', $url) or return;
   my $ref = $self->brik_help_run_invalid_arg('mirror', $url, 'SCALAR', 'ARRAY') or return;

   my @files = ();
   if ($ref eq 'ARRAY') {
      $self->brik_help_run_empty_array_arg('mirror', $url) or return;

      for my $this (@$url) {
         my $file = $self->mirror($this, $output) or next;
         push @files, @$file;
      }
   }
   else {
      if ($url !~ /^https?:\/\// && $url !~ /^ftp:\/\//) {
         return $self->log->error("mirror: invalid URL [$url]");
      }

      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      if (! defined($output)) {
         my $filename = $sf->basefile($url) or return;
         $output = $datadir.'/'.$filename;
      }
      else { # $output is defined
         if (! $sf->is_absolute($output)) {  # We want default datadir for output file
            $output = $datadir.'/'.$output;
         }
      }

      $self->debug && $self->log->debug("mirror: url[$url] output[$output]");

      my $mech = $self->create_user_agent or return;
      LWP::UserAgent::ProgressAny::__add_handlers($mech);
      Progress::Any::Output->set("TermProgressBarColor");

      my $rc;
      eval {
         $rc = $mech->mirror($url, $output);
      };
      if ($@) {
         chomp($@);
         return $self->log->error("mirror: mirroring URL [$url] to local file [$output] failed: $@");
      }
      my $code = $rc->code;
      if ($code == 200) {
         push @files, $output;
         $self->log->info("mirror: downloading URL [$url] to local file [$output] done");
      }
      elsif ($code == 304) { # Not modified
         $self->log->info("mirror: file [$output] not modified since last check");
      }
      else {
         return $self->log->error("mirror: error while mirroring URL [$url] with code: [$code]");
      }
   }

   return \@files;
}

sub parse {
   my $self = shift;
   my ($html) = @_;

   $self->brik_help_run_undef_arg('parse', $html) or return;

   return HTML::TreeBuilder->new_from_content($html);
}

sub get_last {
   my $self = shift;

   return $self->_last;
}

1;

__END__

=head1 NAME

Metabrik::Client::Www - client::www Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
