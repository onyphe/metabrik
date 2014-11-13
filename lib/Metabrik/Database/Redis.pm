#
# $Id$
#
# database::redis Brik
#
package Metabrik::Database::Redis;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable database redis) ],
      attributes => {
         server => [ qw(ip_address) ],
         port => [ qw(port) ],
         _redis => [ ],
      },
      attributes_default => {
         server => '127.0.0.1',
         port => 6379,
      },
      commands => {
         self => [ ],
         connect => [ ],
         time => [ ],
         disconnect => [ ],
         quit => [ ],  # Same as disconnect
         dbsize => [ ],
         exists => [ qw(key) ],
         get => [ qw(key) ],
         set => [ qw(key value) ],
         del => [ qw(key) ],
         mget => [ qw($key_list) ],
         hset => [ qw(hash_name $hash_hash) ],
      },
      require_modules => {
         'Redis' => [ ],
      },
   };
}

# Command list: http://redis.io/commands

sub self {
   my $self = shift;

   my $redis = $self->_redis;
   if (defined($redis)) {
      return $redis;
   }

   $self->log->info("redis: not connected?");

   return 0;
}

sub connect {
   my $self = shift;

   my $redis = Redis->new(
      server => $self->server.':'.$self->port,
      name => 'redis_connection',
      cnx_timeout => $self->global->ctimeout,
      read_timeout => $self->global->rtimeout,
      write_timeout => $self->global->rtimeout,
   ) or return $self->log->error("connect: redis connection error");

   $self->_redis($redis);

   return 1;
}

sub time {
   my $self = shift;

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $value = $redis->time;

   return $value;
}

sub disconnect {
   my $self = shift;

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $value = $redis->quit;

   $self->_redis(undef);

   return $value;
}

sub quit {
   my $self = shift;

   return $self->disconnect;
}

sub dbsize {
   my $self = shift;

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $value = $redis->dbsize;

   return $value;
}

sub exists {
   my $self = shift;
   my ($key) = @_;

   if (! defined($key)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $value = $redis->exists($key);

   return $value;
}

sub get {
   my $self = shift;
   my ($key) = @_;

   if (! defined($key)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $value = $redis->get($key);

   return $value;
}

sub set {
   my $self = shift;
   my ($key, $value) = @_;

   if (! defined($key) || ! defined($value)) {
      return $self->log->error($self->brik_help_run('set'));
   }

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $r = $redis->set($key => $value);

   return $r;
}

sub del {
   my $self = shift;
   my ($key) = @_;

   if (! defined($key)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $value = $redis->del($key);

   return $value;
}

sub mget {
   my $self = shift;
   my ($key_list) = @_;

   if (! defined($key_list)) {
      return $self->log->error($self->brik_help_run('mget'));
   }

   if (ref($key_list) ne 'ARRAY') {
      return $self->log->error('mget: argument 2 must be ARRAYREF');
   }

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my @values = $redis->mget(@$key_list);

   return \@values;
}

sub hset {
   my $self = shift;
   my ($hashname, $hash) = @_;

   if (! defined($hashname) || ! defined($hash)) {
      return $self->log->error($self->brik_help_run('hset'));
   }

   if (ref($hash) ne 'HASH') {
      return $self->log->error('hset: argument 2 must be HASHREF');
   }

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   for (keys %$hash) {
      $redis->hset($hashname, $_, $hash->{$_});
   }

   return $redis->wait_all_responses;
}

1;

__END__
