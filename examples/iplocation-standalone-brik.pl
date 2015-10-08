#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Metabrik::Core::Context;
use Metabrik::Lookup::Iplocation;

my $context = Metabrik::Core::Context->new;
$context->brik_init or die("[FATAL] context init failed\n");

my $li = Metabrik::Lookup::Iplocation->new_from_brik_init($context);
$li->update;

my $info = $li->from_ip("104.47.125.219");

print Dumper($info);
