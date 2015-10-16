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
      tags => [ qw(unstable browser http client www javascript screenshot) ],
      attributes => {
         uri => [ qw(uri) ],
         mechanize => [ qw(INTERNAL) ],
         ssl_verify => [ qw(0|1) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         ignore_body => [ qw(0|1) ],
         user_agent => [ qw(user_agent) ],
      },
      attributes_default => {
         ssl_verify => 1,
         ignore_body => 0,
      },
      commands => {
         create_user_agent => [ ],
         get => [ qw(uri|OPTIONAL) ],
         trace_redirect => [ qw(uri|OPTIONAL) ],
         content => [ ],
         post => [ qw(content_string uri|OPTIONAL) ],
         info => [ ],
         forms => [ ],
         links => [ ],
         headers => [ ],
         status => [ ],
         screenshot => [ qw(uri output_file) ],
         eval_javascript => [ qw(js uri|OPTIONAL) ],
      },
      require_modules => {
         'Net::SSL' => [ ],
         'Data::Dumper' => [ ],
         'IO::Socket::SSL' => [ ],
         'LWP::UserAgent' => [ ],
         'LWP::ConnCache' => [ ],
         'URI' => [ ],
         'WWW::Mechanize' => [ ],
         'WWW::Mechanize::PhantomJS' => [ ],
         'Net::SSLeay' => [ ],
         'Metabrik::File::Write' => [ ],
         'Metabrik::Client::Ssl' => [ ],
      },
      require_binaries => {
         'phantomjs' => [ ],
      },
   };
}

sub create_user_agent {
   my $self = shift;

   $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'Net::SSL';

   my $mech = WWW::Mechanize->new(
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
      $mech->agent_alias('Linux Mozilla');
   }

   if (defined($self->username) && defined($self->password)) {
      $self->log->verbose("create_user_agent: using Basic authentication");
      $mech->cookie_jar({});
      $mech->credentials($self->username, $self->password);
   }

   return $mech;
}

sub _mech_new {
   my $self = shift;
   my ($uri) = @_;

   # We have to use a different method to check certificate because all 
   # IO::Socket::SSL, Net::SSL, Net::SSLeay, Net::HTTPS, AnyEvent::TLS just sucks.
   # So we have to perform a first TCP connexion to verify cert, then a second 
   # One to actually negatiate an unverified session.
   if ($self->ssl_verify) {
      my $cs = Metabrik::Client::Ssl->new_from_brik($self) or return;
      my $verified = $cs->verify_server($uri);
      if (! defined($verified)) {
         return;
      }
      if ($verified == 0) {
         return $self->log->error("_mech_new: server [$uri] not verified");
      }
   }

   return $self->create_user_agent;
}

sub get {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $uri ||= $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   my $mech = $self->_mech_new($uri)
      or return $self->log->error("get: unable to create WWW::Mechanize object");

   $self->mechanize($mech);

   $self->log->verbose("get: $uri");

   my $response;
   eval {
      $response = $mech->get($uri);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get: unable to get uri [$uri]: $@");
   }

   my %response = ();
   $response{code} = $response->code;
   if (! $self->ignore_body) {
      $response{body} = $response->decoded_content;
   }

   my $headers = $response->headers;
   $response{headers} = { map { $_ => $headers->{$_} } keys %$headers };
   delete $response{headers}->{'::std_case'};

   return \%response;
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
   my ($data, $uri) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('post'));
   }

   $uri ||= $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   my $mech = $self->_mech_new($uri)
      or return $self->log->error("get: unable to create WWW::Mechanize object");

   $self->mechanize($mech);

   $self->log->verbose("post: $uri");

   my $response;
   eval {
      $response = $mech->post($uri, Content => $data);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("post: unable to post uri [$uri]: $@");
   }

   my %response = ();
   $response{code} = $response->code;
   if (! $self->ignore_body) {
      $response{body} = $response->decoded_content;
   }

   my $headers = $response->headers;
   $response{headers} = { map { $_ => $headers->{$_} } keys %$headers };
   delete $response{headers}->{'::std_case'};

   return \%response;
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
      $self->log->verbose("links: found link [".$l->url."]");
   }

   return \@links;
}

sub headers {
   my $self = shift;

   if (! defined($self->mechanize)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $headers = $self->mechanize->response->headers;

   return $headers;
}

sub status {
   my $self = shift;

   if (! defined($self->mechanize)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $mech = $self->mechanize;

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

sub trace_redirect {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $uri ||= $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_set('uri'));
   }

   my %args = ();
   if (! $self->ssl_verify) {
      $args{ssl_opts} = { SSL_verify_mode => 'SSL_VERIFY_NONE'};
   }

   my $lwp = LWP::UserAgent->new(%args);
   $lwp->timeout($self->global->rtimeout);
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

   my $mech = WWW::Mechanize::PhantomJS->new
      or return $self->log->error("screenshot: PhantomJS failed");
   $mech->get($uri)
      or return $self->log->error("screenshot: get uri [$uri] failed");

   my $data = $mech->content_as_png
      or return $self->log->error("screenshot: content_as_png failed");

   my $write = Metabrik::File::Write->new_from_brik($self) or return;
   $write->encoding('ascii');
   $write->overwrite(1);
   $write->append(0);

   $write->open($output) or return $self->log->error("screenshot: open failed");
   $write->write($data) or return $self->log->error("screenshot: write failed");
   $write->close;

   return $output;
}

sub eval_javascript {
   my $self = shift;
   my ($js, $uri) = @_;

   # Perl module Wight may also be an option.

   my $mech = WWW::Mechanize::PhantomJS->new
      or return $self->log->error("eval_javascript: PhantomJS failed");

   if ($uri) {
      $mech->get($uri)
         or return $self->log->error("eval_javascript: get uri [$uri] failed");
   }

   return $mech->eval_in_page($js);
}

1;

__END__

=head1 NAME

Metabrik::Client::Www - client::www Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
