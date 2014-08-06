#
# HTTP::Proxy plugin
#
package Plashy::Plugin::Httpproxy;
use strict;
use warnings;

use base qw(Plashy::Plugin);

our @AS = qw(
   port
   truncate_request
   truncate_response
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use HTTP::Proxy;
use HTTP::Proxy::HeaderFilter::simple;
use LWP::Protocol::connect;

sub new {
   my $self = shift->SUPER::new(
      port => 3128,
      truncate_response => 512,
      @_,
   );

   return $self;
}

sub help {
   print "set httpproxy port <port> (default: 3128)\n";
   print "set httpproxy truncate_response <characters> (default: 0, do not truncate)\n";
   print "set httpproxy truncate_request <characters> (default: 512 characters)\n";
   print "\n";
   print "run httpproxy requests - simply display browser requests\n";
   print "run httpproxy requests_responses - simply display browser requests and server responses\n";
}

# XXX: see http://cpansearch.perl.org/src/MIKEM/Net-SSLeay-1.65/examples/https-proxy-snif.pl
# XXX: for HTTPS mitm

sub requests {
   my $self = shift;

   my $proxy = HTTP::Proxy->new(
      port => $self->port,
   );

   $proxy->push_filter(
      request => HTTP::Proxy::HeaderFilter::simple->new(
         sub {
            my ($self, $headers, $request) = @_;
            my $string = $request->as_string;
            if ($self->truncate_request) {
               print substr($string, 0, $self->truncate_request);
               print "\n[..]\n";
            }
            else {
               print $string;
            }
         },
      ),
   );

   print "Listening on port: ".$self->port."\n";
   print "Ready to process browser requests, blocking state...\n";

   return $proxy->start;
}

sub requests_responses {
   my $self = shift;

   my $proxy = HTTP::Proxy->new(
      port => $self->port,
   );

   $proxy->push_filter(
      request => HTTP::Proxy::HeaderFilter::simple->new(
         sub {
            my ($proxy, $headers, $request) = @_;
            my $string = $request->as_string;
            if ($self->truncate_request) {
               print substr($string, 0, $self->truncate_request);
               print "\n[..]\n";
            }
            else {
               print $string;
            }
         },
      ),
      response => HTTP::Proxy::HeaderFilter::simple->new(
         sub {
            my ($proxy, $headers, $response) = @_;
            my $string = $response->as_string;
            if ($self->truncate_response) {
               print substr($string, 0, $self->truncate_response);
               print "\n[..]\n";
            }
            else {
               print $string;
            }
         },
      ),
   );

   print "Listening on port: ".$self->port."\n";
   print "Ready to process browser requests, blocking state...\n";

   return $proxy->start;
}

1;

__END__
