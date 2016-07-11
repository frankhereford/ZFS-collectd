#!/usr/bin/perl

use strict;
use Redis;

my $redis = Redis->new;

print "Snapshot count: ", $redis->get('snapshot_count'), "\n";



